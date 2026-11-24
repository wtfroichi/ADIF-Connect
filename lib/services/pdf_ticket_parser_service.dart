import 'package:flutter/services.dart';

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
    final text = await _channel.invokeMethod<String>('extractPdfText', bytes);
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
    final origin = _findStation(normalizedLines, const [
          'origen',
          'origin',
          'salida',
          'from',
          'estación de salida',
          'estacion de salida',
        ]) ??
        _findStationInDocument(normalizedLines, first: true);
    final destination = _findStation(normalizedLines, const [
          'destino',
          'destination',
          'llegada',
          'to',
          'estación de llegada',
          'estacion de llegada',
        ]) ??
        _findStationInDocument(normalizedLines, first: false);
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
    final normalizedService = OperatorThemes.normalizeRenfeService(joinedText);
    final service = operator == RailOperator.iryo
        ? 'IRYO'
        : operator == RailOperator.ouigo
            ? 'OUIGO'
            : normalizedService;
    final ticketNumber = _findLabeledValue(
          normalizedLines,
          const ['número de billete', 'numero de billete', 'billete'],
          RegExp(r'\b\d{13}\b'),
        ) ??
        RegExp(r'\b\d{13}\b').firstMatch(joinedText)?.group(0);
    final localizer = _findLabeledValue(
          normalizedLines,
          const ['localizador', 'locator', 'pnr'],
          RegExp(r'\b[A-Z0-9]{5,8}\b', caseSensitive: false),
        ) ??
        '';
    final trainNumber = _findLabeledValue(
          normalizedLines,
          const ['número de tren', 'numero de tren', 'tren', 'train'],
          RegExp(r'\b[A-Z0-9-]{3,8}\b', caseSensitive: false),
        ) ??
        '';
    final coach = _findLabeledValue(
          normalizedLines,
          const ['coche', 'coach'],
          RegExp(r'\b[A-Z0-9-]{1,5}\b', caseSensitive: false),
        ) ??
        '';
    final seat = _findLabeledValue(
          normalizedLines,
          const ['asiento', 'asento', 'plaza', 'seat'],
          RegExp(r'\b[A-Z0-9-]{1,8}\b', caseSensitive: false),
        ) ??
        '';
    final seatClass = _findLabeledValue(
          normalizedLines,
          const ['tarifa', 'clase', 'class', 'fare'],
          RegExp(r'[A-ZÁÉÍÓÚÜÑ][A-ZÁÉÍÓÚÜÑ ]{1,24}', caseSensitive: false),
        ) ??
        '';
    final platform = _findLabeledValue(
      normalizedLines,
      const ['vía', 'via', 'anden', 'platform'],
      RegExp(r'\b\d{1,2}[A-Z]?\b', caseSensitive: false),
    );
    final passenger = _findLabeledValue(
          normalizedLines,
          const ['pasajero', 'viajero', 'passenger'],
          RegExp(r'[A-ZÁÉÍÓÚÜÑ][A-ZÁÉÍÓÚÜÑ ,.' '-]{2,48}',
              caseSensitive: false),
        ) ??
        '';
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
