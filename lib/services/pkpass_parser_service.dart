import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/operator_themes.dart';
import '../models/ticket_model.dart';

class PkpassParserService {
  /// Unzips a genuine .pkpass archive, extracts pass.json, and maps all Renfe/ADIF fields to TicketModel.
  static TicketModel parse(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw const FormatException(AppStrings.pkpassInvalidArchive);
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? passJsonFile;

    for (final file in archive) {
      if (file.name == 'pass.json') {
        passJsonFile = file;
        break;
      }
    }

    if (passJsonFile == null) {
      throw const FormatException(AppStrings.pkpassMissingPassJson);
    }

    final contentString = utf8.decode(passJsonFile.content as List<int>);
    final Map<String, dynamic> passJson =
        jsonDecode(contentString) as Map<String, dynamic>;

    return _mapPassJsonToTicket(passJson);
  }

  static TicketModel _mapPassJsonToTicket(Map<String, dynamic> json) {
    final passType = json['passTypeIdentifier']?.toString();
    final orgName = json['organizationName']?.toString();
    final description = json['description']?.toString();
    final operator = OperatorThemes.detect('$passType $orgName $description');

    // Renfe passes place data under 'boardingPass' or 'generic'
    final passData = (json['boardingPass'] ??
        json['generic'] ??
        json['eventTicket'] ??
        <String, dynamic>{}) as Map<String, dynamic>;

    final primaryFields = _asList(passData['primaryFields']);
    final secondaryFields = _asList(passData['secondaryFields']);
    final auxiliaryFields = _asList(passData['auxiliaryFields']);
    final headerFields = _asList(passData['headerFields']);
    final backFields = _asList(passData['backFields']);

    final allFields = [
      ...primaryFields,
      ...secondaryFields,
      ...auxiliaryFields,
      ...headerFields,
      ...backFields,
    ];

    // 1. Resolve endpoint names from field keys or station-name labels.
    final originKeys = [
      'origin',
      'origen',
      'from',
      'saída',
      'salida',
      'orixe',
      'estacionorigen'
    ];
    final destinationKeys = [
      'destination',
      'destino',
      'to',
      'llegada',
      'chegada',
      'estaciondestino'
    ];
    final originField = _findStationField(primaryFields, originKeys) ??
        _findPositionalStationField(primaryFields, 0) ??
        _findStationField(allFields, originKeys) ??
        _findCandidateStationField(allFields, first: true);
    final destField = _findStationField(primaryFields, destinationKeys) ??
        _findPositionalStationField(primaryFields, 1) ??
        _findStationField(allFields, destinationKeys) ??
        _findCandidateStationField(allFields, first: false);
    final origin = _stationNameAndCode(originField);
    final destination = _stationNameAndCode(destField);
    final originVal = origin.$1;
    final originCode = origin.$2;
    final destVal = destination.$1;
    final destCode = destination.$2;

    // 2. Train Number & Commercial Product
    final trainNumber = _findValue(
            [...secondaryFields, ...auxiliaryFields, ...headerFields],
            ['tren', 'train', 'trainnumber', 'numerotren', 'numtren']) ??
        _findValue(allFields, ['tren', 'train', 'trainnumber', 'numerotren']) ??
        '';

    final trainLabels = [
      ...secondaryFields,
      ...auxiliaryFields,
      ...headerFields,
      ...primaryFields,
    ].map((field) => '${field['key'] ?? ''} ${field['label'] ?? ''}').join(' ');
    final productRaw = _normalizeTrainProduct(
      '${_findValue(allFields, [
                'producto',
                'product',
                'servicio',
                'tipotren',
                'comercial',
                'categoria'
              ]) ?? ''} $trainLabels ${_inferTrainType(operator)}',
    );

    // 3. Coach & Seat
    final coach = _findValue(
            [...secondaryFields, ...auxiliaryFields, ...headerFields],
            ['coche', 'coach', 'car', 'vagon']) ??
        _findValue(allFields, ['coche', 'coach', 'car']) ??
        '';
    final seat =
        _findValue(secondaryFields, ['plaza', 'asiento', 'seat', 'asento']) ??
            _findValue(allFields, ['plaza', 'asiento', 'seat', 'asento']) ??
            '';

    // 4. Tariff / Class
    final seatClass = _findValue(
            auxiliaryFields, ['tarifa', 'clase', 'class', 'fare', 'billete']) ??
        _findValue(allFields, ['tarifa', 'clase', 'class']) ??
        '';

    // 5. Platform (Vía)
    final platform = _findExplicitValue(allFields, {
      'via',
      'platform',
      'anden',
    });

    // 6. Booking Locator & Passenger Name
    final localizer = _findValue(backFields, [
          'localizador',
          'localizadorrenfe',
          'pnr',
          'locator',
          'booking',
          'codlocalizador'
        ]) ??
        _findValue(allFields, ['localizador', 'pnr', 'locator', 'booking']) ??
        json['serialNumber']?.toString() ??
        '';

    final passenger = _findValue(backFields, [
          'viajero',
          'pasajero',
          'passenger',
          'pasaxeiro',
          'nombre',
          'name'
        ]) ??
        _findValue(allFields,
            ['viajero', 'pasajero', 'passenger', 'pasaxeiro', 'nombre']) ??
        '';

    // 7. Dates & Europe/Madrid Timezone Conversion
    final relevantDateStr = json['relevantDate']?.toString();
    final dateField = _findTravelDate(allFields);
    final depClock = _clockForStationField(originField) ??
        _findValue(allFields, ['horasalida', 'departuretime', 'departure']);
    final arrClock = _clockForStationField(destField) ??
        _findValue(allFields, ['horallegada', 'arrivaltime', 'arrival']);
    final travelDate =
        _madridDateTime(relevantDateStr) ?? _parseTravelDate(dateField);
    if (travelDate == null) {
      throw const FormatException(AppStrings.pkpassMissingTravelDate);
    }
    if (depClock == null) {
      throw const FormatException(AppStrings.pkpassMissingDepartureTime);
    }
    if (arrClock == null) {
      throw const FormatException(AppStrings.pkpassMissingArrivalTime);
    }
    final departureTime = _dateWithClock(travelDate, depClock);
    if (departureTime == null) {
      throw const FormatException(AppStrings.pkpassInvalidDepartureTime);
    }
    var arrivalTime = _dateWithClock(travelDate, arrClock);
    if (arrivalTime == null) {
      throw const FormatException(AppStrings.pkpassInvalidArrivalTime);
    }
    if (arrivalTime.isBefore(departureTime)) {
      arrivalTime = arrivalTime.add(const Duration(days: 1));
    }

    // 8. Barcode Extraction
    TicketBarcode? barcode;
    if (json['barcodes'] is List && (json['barcodes'] as List).isNotEmpty) {
      barcode = TicketBarcode.fromJson(
          (json['barcodes'] as List).first as Map<String, dynamic>);
    } else if (json['barcode'] is Map) {
      barcode = TicketBarcode.fromJson(json['barcode'] as Map<String, dynamic>);
    }

    final serial = json['serialNumber']?.toString() ?? '';

    return TicketModel(
      id: serial,
      operator: operator,
      origin: originVal,
      originCode:
          originCode.isNotEmpty ? originCode : _extractStationCode(originVal),
      destination: destVal,
      destinationCode:
          destCode.isNotEmpty ? destCode : _extractStationCode(destVal),
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      trainNumber: trainNumber,
      trainType: productRaw,
      coach: coach,
      seat: seat,
      seatClass: seatClass,
      platform: platform,
      passengerName: passenger,
      bookingReference: localizer.toUpperCase(),
      barcode: barcode,
    );
  }

  static DateTime? _madridDateTime(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final hasOffset =
        value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
    if (!hasOffset) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
      );
    }

    final utc = parsed.toUtc();
    final madrid = utc.add(Duration(hours: _isMadridSummerTime(utc) ? 2 : 1));
    return DateTime(
        madrid.year, madrid.month, madrid.day, madrid.hour, madrid.minute);
  }

  static bool _isMadridSummerTime(DateTime utc) {
    final year = utc.year;
    final marchLastDay = DateTime.utc(year, 3, 31);
    final octoberLastDay = DateTime.utc(year, 10, 31);
    final summerStarts = DateTime.utc(
      year,
      3,
      31 - marchLastDay.weekday % 7,
      1,
    );
    final summerEnds = DateTime.utc(
      year,
      10,
      31 - octoberLastDay.weekday % 7,
      1,
    );
    return !utc.isBefore(summerStarts) && utc.isBefore(summerEnds);
  }

  static DateTime? _parseTravelDate(String? value) {
    if (value == null) return null;
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  static DateTime? _dateWithClock(DateTime date, String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String? _clockForStationField(Map<String, dynamic>? field) {
    final value = field?['value']?.toString().trim();
    return value != null && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)
        ? value
        : null;
  }

  static String? _findTravelDate(List<Map<String, dynamic>> fields) {
    for (final field in fields) {
      final key = _normalizedField(field['key']);
      final label = _normalizedField(field['label']);
      if (key.contains('fechaventa') ||
          key.contains('emision') ||
          label.contains('emision') ||
          label.contains('venta')) {
        continue;
      }
      if (key.contains('fecha') || key == 'date' || label == 'fecha') {
        final value = field['value']?.toString();
        if (_parseTravelDate(value) != null) return value;
      }
    }
    return null;
  }

  static String _extractStationCode(String stationName) {
    return AdifStations.byName(stationName)?.adifCode ?? '';
  }

  static (String, String) _stationNameAndCode(Map<String, dynamic>? field) {
    if (field == null) return ('', '');
    final label = field['label']?.toString().trim() ?? '';
    final value = field['value']?.toString().trim() ?? '';
    if (label.isEmpty && value.isEmpty) return ('', '');

    if (_isGenericStationLabel(label)) {
      return _stationFromToken(value);
    }

    final labelStation = AdifStations.byName(label);
    if (labelStation != null) {
      return (
        labelStation.name,
        _looksLikeStationCode(value) ? value : labelStation.adifCode,
      );
    }
    if (_looksLikeStationCode(label)) {
      final station = AdifStations.byCode(label) ?? AdifStations.byName(value);
      return (station?.name ?? '', label);
    }

    if (_looksLikeStationCode(value)) {
      if (_isNonStationField(label, field['key']?.toString() ?? '')) {
        return ('', value);
      }
      return (label, value);
    }

    final valueStation =
        AdifStations.byCode(value) ?? AdifStations.byName(value);
    if (valueStation != null) return (valueStation.name, valueStation.adifCode);
    if (_clockForStationField(field) != null &&
        !_isNonStationField(label, field['key']?.toString() ?? '')) {
      return (label, '');
    }

    if (!_isNonStationField(label, field['key']?.toString() ?? '') &&
        !_isDateValue(value)) {
      return (value.isNotEmpty ? value : label, '');
    }
    return ('', '');
  }

  static (String, String) _stationFromToken(String token) {
    if (token.isEmpty || _isDateValue(token) || _clockValue(token)) {
      return ('', '');
    }
    final station = AdifStations.byCode(token) ?? AdifStations.byName(token);
    if (station != null) {
      return (
        station.name,
        _looksLikeStationCode(token) ? token : station.adifCode,
      );
    }
    return _looksLikeStationCode(token) ? ('', token) : (token, '');
  }

  static bool _isGenericStationLabel(String label) {
    final normalized = AdifStations.normalize(label).toUpperCase();
    return const {
      'ORIGEN',
      'ORIXE',
      'DESTINO',
      'SALIDA',
      'SAIDA',
      'LLEGADA',
      'CHEGADA',
      'ORIGIN',
      'DESTINATION',
      'DEPARTURE',
      'ARRIVAL',
    }.contains(normalized);
  }

  static bool _isDateValue(String value) =>
      RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(value) ||
      RegExp(r'^\d{4}-\d{2}-\d{2}(?:$|T)').hasMatch(value);

  static bool _clockValue(String value) =>
      RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value);

  static bool _isNonStationField(String label, String key) {
    final normalizedLabel = _normalizedField(label);
    final normalizedKey = _normalizedField(key);
    const metadataKeys = [
      'fecha',
      'date',
      'localizador',
      'booking',
      'pnr',
      'asiento',
      'asento',
      'plaza',
      'seat',
      'coche',
      'coach',
      'tren',
      'train',
      'pasajero',
      'pasaxeiro',
      'viajero',
      'passenger',
      'nombre',
      'nome',
      'name',
      'clase',
      'class',
      'tarifa',
      'fare',
      'produto',
      'producto',
      'product',
      'servicio',
      'service',
      'operador',
      'operator',
    ];
    return metadataKeys.any(
      (keyPart) =>
          normalizedLabel.contains(keyPart) || normalizedKey.contains(keyPart),
    );
  }

  static bool _looksLikeStationCode(String value) {
    final clean = value.trim();
    return RegExp(r'^\d{3,5}$').hasMatch(clean) ||
        RegExp(r'^[A-Z]{3,4}$', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'^[A-Z]{2,5}-[A-Z0-9]+$', caseSensitive: false).hasMatch(clean);
  }

  static Map<String, dynamic>? _findStationField(
    List<Map<String, dynamic>> fields,
    List<String> matchKeys,
  ) {
    final normalizedMatches = matchKeys.map(AdifStations.normalize).toSet();
    for (final field in fields) {
      final key = _normalizedField(field['key']);
      final label = _normalizedField(field['label']);
      final isStationField = normalizedMatches.any(
        (match) => key == match || key.contains(match) || label == match,
      );
      if (isStationField && _isStationFieldCandidate(field)) {
        return field;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findCandidateStationField(
    List<Map<String, dynamic>> fields, {
    required bool first,
  }) {
    final candidates = fields.where(_isStationFieldCandidate).toList();
    if (candidates.isEmpty) return null;
    return first ? candidates.first : candidates.last;
  }

  static Map<String, dynamic>? _findPositionalStationField(
    List<Map<String, dynamic>> fields,
    int index,
  ) {
    if (index >= fields.length || !_isStationFieldCandidate(fields[index])) {
      return null;
    }
    return fields[index];
  }

  static bool _isStationFieldCandidate(Map<String, dynamic> field) {
    final label = field['label']?.toString().trim() ?? '';
    final key = field['key']?.toString() ?? '';
    final value = field['value']?.toString().trim() ?? '';
    if (value.isEmpty || _isDateValue(value)) return false;
    if (_isDateValue(field['label']?.toString() ?? '') ||
        _normalizedField(key).contains('fecha') ||
        _normalizedField(key).contains('date')) {
      return false;
    }
    final (name, code) = _stationNameAndCode(field);
    if (name.isEmpty && code.isEmpty) return false;
    return !_isNonStationField(label, key) ||
        AdifStations.byName(label) != null;
  }

  static String _normalizedField(dynamic value) =>
      value == null ? '' : AdifStations.normalize(value.toString());

  static String? _findExplicitValue(
    List<Map<String, dynamic>> fields,
    Set<String> keys,
  ) {
    for (final field in fields) {
      final key = _normalizedField(field['key']);
      final label = _normalizedField(field['label']);
      if (keys.contains(key) || keys.contains(label)) {
        final value = field['value']?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static String _normalizeTrainProduct(String raw) {
    return OperatorThemes.normalizeRenfeService(raw);
  }

  static String _inferTrainType(RailOperator operator) {
    switch (operator) {
      case RailOperator.renfe:
      case RailOperator.renfeAve:
      case RailOperator.renfeAvant:
      case RailOperator.renfeAlvia:
      case RailOperator.renfeIntercity:
      case RailOperator.renfeMd:
      case RailOperator.renfeCercanias:
      case RailOperator.renfeRegional:
        return '';
      case RailOperator.renfeAvlo:
        return 'AVLO';
      case RailOperator.iryo:
        return 'IRYO';
      case RailOperator.ouigo:
        return 'OUIGO';
      case RailOperator.adif:
      case RailOperator.unknown:
        return '';
    }
  }

  static List<Map<String, dynamic>> _asList(dynamic val) {
    if (val is List) {
      return val.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  static String? _findValue(
      List<Map<String, dynamic>> fields, List<String> matchKeys) {
    for (final field in fields) {
      final key = field['key']
              ?.toString()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '') ??
          '';
      final label = field['label']
              ?.toString()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '') ??
          '';
      for (final match in matchKeys) {
        final cleanMatch =
            match.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (key == cleanMatch ||
            label == cleanMatch ||
            key.contains(cleanMatch) ||
            label.contains(cleanMatch)) {
          final val = field['value']?.toString();
          if (val != null && val.isNotEmpty) return val;
        }
      }
    }
    return null;
  }
}
