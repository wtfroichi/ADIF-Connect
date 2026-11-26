import 'package:flutter/services.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/operator_themes.dart';
import '../models/ticket_model.dart';

abstract final class PdfTicketParserService {
  static const MethodChannel _channel = MethodChannel('es.adifconnect.app/pdf');
  static final RegExp _timePattern = RegExp(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b');
  static final RegExp _datePattern = RegExp(
    r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b|\b(20\d{2})-(\d{2})-(\d{2})\b',
  );

  static Future<TicketModel> parse(Uint8List bytes) async {
    String? text;
    if (Platform.isAndroid) {
      final document = PdfDocument(inputBytes: bytes);
      try {
        text = PdfTextExtractor(document).extractText();
      } finally {
        document.dispose();
      }
    } else {
      text = await _channel.invokeMethod<String>('extractPdfText', bytes);
    }
    if (text == null || text.trim().isEmpty) {
      throw const FormatException(AppStrings.pdfTextUnavailable);
    }

    final normalizedLines = text
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final joinedText = normalizedLines.join('\n');
    final locatorMatch = RegExp(
      r'Localizador:\s*([A-Z0-9]{6,8})',
      caseSensitive: false,
    ).firstMatch(joinedText);
    final localizer = locatorMatch?.group(1)?.toUpperCase() ??
        (_findLabeledValue(
              normalizedLines,
              const ['localizador', 'locator', 'pnr'],
              RegExp(r'\b[A-Z0-9]{5,8}\b', caseSensitive: false),
            ) ??
            '');
    var cleanedText = joinedText;
    if (localizer.isNotEmpty) {
      cleanedText = cleanedText.replaceAll(
        RegExp(
          r'\d{4}-\d{2}-\d{2}\s+' +
              RegExp.escape(localizer) +
              r'[^\n]*(?:Turista|Elige|Confort).*',
          caseSensitive: false,
        ),
        '',
      );
    }
    final cleanedLines = cleanedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final originMatch = RegExp(
      r'Origen:\s*([A-ZÁÉÍÓÚÑ0-9\s\-\.]+)',
      caseSensitive: false,
    ).firstMatch(cleanedText);
    final destinationMatch = RegExp(
      r'Destino:\s*([A-ZÁÉÍÓÚÑ0-9\s\-\.]+)',
      caseSensitive: false,
    ).firstMatch(cleanedText);
    final originText = _cleanStationField(originMatch?.group(1));
    final destinationText = _cleanStationField(destinationMatch?.group(1));
    final origin = (originText == null ? null : _stationInText(originText)) ??
        _findStation(cleanedLines, const [
          'origen',
          'origin',
          'salida',
          'from',
          'estación de salida',
          'estacion de salida',
        ]) ??
        _findStationInDocument(cleanedLines, first: true);
    final destination =
        (destinationText == null ? null : _stationInText(destinationText)) ??
            _findStation(cleanedLines, const [
              'destino',
              'destination',
              'llegada',
              'to',
              'estación de llegada',
              'estacion de llegada',
            ]) ??
            _findStationInDocument(cleanedLines, first: false);
    if (origin == null ||
        destination == null ||
        origin.adifCode == destination.adifCode) {
      throw const FormatException(AppStrings.pdfMissingStations);
    }

    final date = _parseDate(joinedText);
    if (date == null) {
      throw const FormatException(AppStrings.pdfMissingDate);
    }
    final times = _timePattern
        .allMatches(joinedText)
        .map((match) => match.group(0)!)
        .toList();
    final departureClock = _findTimeNearLabel(normalizedLines, const [
          'salida',
          'departure',
          'hora de salida',
        ]) ??
        (times.isNotEmpty ? times.first : null);
    final arrivalClock = _findTimeNearLabel(normalizedLines, const [
          'llegada',
          'arrival',
          'hora de llegada',
        ]) ??
        (times.length > 1 ? times[1] : null);
    if (departureClock == null || arrivalClock == null) {
      throw const FormatException(AppStrings.pdfMissingTimes);
    }

    final departure = _dateWithTime(date, departureClock);
    var arrival = _dateWithTime(date, arrivalClock);
    if (arrival.isBefore(departure)) {
      arrival = arrival.add(const Duration(days: 1));
    }

    final operator = OperatorThemes.detect(joinedText);
    final trainMatch = RegExp(
      r'\b(AVE|AVLO|AVANT|INTERCITY|ALVIA|EUROMED|TALGO|MD|MEDIA DISTANCIA|REGIONAL|CERCANIAS|CERCANÍAS|IRYO|OUIGO)\s+(\d{4,5})\b',
      caseSensitive: false,
    ).firstMatch(cleanedText);
    final normalizedService = trainMatch == null
        ? OperatorThemes.normalizeRenfeService(cleanedText)
        : _normalizePdfService(trainMatch.group(1)!);
    final service = operator == RailOperator.iryo
        ? 'IRYO'
        : operator == RailOperator.ouigo
            ? 'OUIGO'
            : normalizedService;
    final ticketNumber = RegExp(
          r'N[º°o]?\s*Billete:\s*(\d{10,16})',
          caseSensitive: false,
        ).firstMatch(cleanedText)?.group(1) ??
        _findLabeledValue(
          normalizedLines,
          const ['número de billete', 'numero de billete', 'billete'],
          RegExp(r'\b\d{13}\b'),
        ) ??
        RegExp(r'\b\d{13}\b').firstMatch(joinedText)?.group(0);
    final trainNumber = trainMatch?.group(2) ??
        _findLabeledValue(
          normalizedLines,
          const ['número de tren', 'numero de tren', 'tren', 'train'],
          RegExp(r'\b[A-Z0-9-]{3,8}\b', caseSensitive: false),
        ) ??
        '';
    final coach = RegExp(
          r'Coche:\s*([A-Z0-9]+)',
          caseSensitive: false,
        ).firstMatch(cleanedText)?.group(1) ??
        _findLabeledValue(
          normalizedLines,
          const ['coche', 'coach'],
          RegExp(r'\b[A-Z0-9-]{1,5}\b', caseSensitive: false),
        ) ??
        '';
    final seat = RegExp(
          r'Plaza:\s*([A-Z0-9]+)',
          caseSensitive: false,
        ).firstMatch(cleanedText)?.group(1) ??
        _findLabeledValue(
          normalizedLines,
          const ['asiento', 'asento', 'plaza', 'seat'],
          RegExp(r'\b[A-Z0-9-]{1,8}\b', caseSensitive: false),
        ) ??
        '';
    final explicitClass = RegExp(
      r'(Elige Confort|Prémium|Premium|Turista|Elige)',
      caseSensitive: false,
    ).firstMatch(cleanedText)?.group(1);
    final seatClass = explicitClass ??
        _findLabeledValue(
          normalizedLines,
          const ['tarifa', 'clase', 'class', 'fare'],
          RegExp(r'[A-ZÁÉÍÓÚÜÑ][A-ZÁÉÍÓÚÜÑ ]{1,24}', caseSensitive: false),
        ) ??
        '';
    const platform = null;
    final passengerMatch = RegExp(
      r'Pasajero:\s*([A-ZÁÉÍÓÚÜÑ][A-ZÁÉÍÓÚÜÑ \-]{2,48})',
      caseSensitive: false,
    ).firstMatch(cleanedText);
    var passenger = passengerMatch?.group(1)?.trim() ??
        _findLabeledValue(
          normalizedLines,
          const ['pasajero', 'viajero', 'passenger'],
          RegExp(r'[A-ZÁÉÍÓÚÜÑ][A-ZÁÉÍÓÚÜÑ ,.' '-]{2,48}',
              caseSensitive: false),
        ) ??
        '';
    if (passenger.length > 48 ||
        passenger.toUpperCase().contains('TURISTA') ||
        passenger.toUpperCase().contains('LOCALIZADOR')) {
      passenger = '';
    }
    final serial = ticketNumber ?? localizer;

    return TicketModel(
      id: 'pdf-${serial.isEmpty ? DateTime.now().microsecondsSinceEpoch : serial}',
      operator: operator,
      origin: origin.name,
      originCode: origin.adifCode,
      destination: destination.name,
      destinationCode: destination.adifCode,
      departureTime: departure,
      arrivalTime: arrival,
      trainNumber: trainNumber,
      trainType: service,
      coach: coach,
      seat: seat,
      seatClass: seatClass,
      platform: platform,
      passengerName: passenger,
      ticketNumber: ticketNumber,
      bookingReference: localizer.toUpperCase(),
      barcode: ticketNumber == null
          ? null
          : TicketBarcode(
              message: ticketNumber,
              format: BarcodeType.aztec,
              rawFormat: 'PKBarcodeFormatAztec',
            ),
    );
  }

  static StationInfo? _findStation(
    List<String> lines,
    List<String> labels,
  ) {
    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = AdifStations.normalize(lines[index]);
      if (!labels.any((label) =>
          normalizedLine.startsWith(AdifStations.normalize(label)))) {
        continue;
      }
      final candidates = [
        lines[index],
        if (index + 1 < lines.length) lines[index + 1],
        if (index + 2 < lines.length) lines[index + 2],
      ];
      for (final candidate in candidates) {
        final station = _stationInText(candidate);
        if (station != null) return station;
      }
    }
    return null;
  }

  static StationInfo? _findStationInDocument(
    List<String> lines, {
    required bool first,
  }) {
    final matches = <(int, StationInfo)>[];
    for (var index = 0; index < lines.length; index++) {
      final station = _stationInText(lines[index]);
      if (station != null) matches.add((index, station));
    }
    if (matches.isEmpty) return null;
    return first ? matches.first.$2 : matches.last.$2;
  }

  static StationInfo? _stationInText(String text) {
    final resolved = AdifStations.resolveName(text.trim());
    final resolvedStation = AdifStations.byName(resolved);
    if (resolvedStation != null) return resolvedStation;
    final normalizedText = AdifStations.normalize(text);
    final matches = AdifStations.all
        .where((station) => normalizedText.contains(
              AdifStations.normalize(station.name),
            ))
        .toList()
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    return matches.isEmpty ? null : matches.first;
  }

  static String? _findTimeNearLabel(List<String> lines, List<String> labels) {
    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = AdifStations.normalize(lines[index]);
      if (!labels.any(
          (label) => normalizedLine.contains(AdifStations.normalize(label)))) {
        continue;
      }
      for (final line in [
        lines[index],
        if (index + 1 < lines.length) lines[index + 1],
      ]) {
        final match = _timePattern.firstMatch(line);
        if (match != null) return match.group(0);
      }
    }
    return null;
  }

  static String? _findLabeledValue(
    List<String> lines,
    List<String> labels,
    RegExp valuePattern,
  ) {
    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = AdifStations.normalize(lines[index]);
      if (!labels.any(
          (label) => normalizedLine.contains(AdifStations.normalize(label)))) {
        continue;
      }
      for (final line in [
        lines[index],
        if (index + 1 < lines.length) lines[index + 1],
      ]) {
        final value = valuePattern.firstMatch(line)?.group(0);
        if (value != null) return value.trim();
      }
    }
    return null;
  }

  static String _normalizePdfService(String raw) {
    final normalized =
        raw.toUpperCase().replaceAll('CERCANÍAS', 'CERCANIAS').trim();
    if (normalized == 'MD' ||
        normalized == 'MEDIA DISTANCIA' ||
        normalized == 'REGIONAL' ||
        normalized == 'CERCANIAS') {
      return normalized == 'CERCANIAS' ? 'RENFE CERCANÍAS' : 'RENFE REGIONAL';
    }
    if (normalized == 'ALVIA' ||
        normalized == 'EUROMED' ||
        normalized == 'TALGO' ||
        normalized == 'INTERCITY') {
      return 'RENFE INTERCITY';
    }
    if (normalized == 'AVLO') return 'RENFE AVLO';
    if (normalized == 'AVANT') return 'RENFE AVANT';
    if (normalized == 'AVE') return 'RENFE AVE';
    if (normalized == 'IRYO') return 'IRYO';
    if (normalized == 'OUIGO') return 'OUIGO';
    return 'RENFE';
  }

  static String? _cleanStationField(String? value) {
    if (value == null) return null;
    var cleaned = value
        .replaceAll(RegExp(r'\b(?:20\d{2})[.-]\d{2}[.-]\d{2}\b'), '')
        .replaceAll(RegExp(r'\b\d{2}/\d{2}/\d{4}\b'), '')
        .replaceAll(
            RegExp(r'\b(?:Coche|Plaza|Destino)\b.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'[,:;\-]+$'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static DateTime? _parseDate(String text) {
    final match = _datePattern.firstMatch(text);
    if (match == null) return null;
    if (match.group(4) != null) {
      return DateTime(
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
      );
    }
    var year = int.parse(match.group(3)!);
    if (year < 100) year += year < 70 ? 2000 : 1900;
    return DateTime(
        year, int.parse(match.group(2)!), int.parse(match.group(1)!));
  }

  static DateTime _dateWithTime(DateTime date, String time) {
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, parts[0], parts[1]);
  }
}
