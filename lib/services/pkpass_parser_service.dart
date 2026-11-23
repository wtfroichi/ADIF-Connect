import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../core/theme/operator_themes.dart';
import '../models/ticket_model.dart';

class PkpassParserService {
  /// Unzips a genuine .pkpass archive, extracts pass.json, and maps all Renfe/ADIF fields to TicketModel.
  static TicketModel parse(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw const FormatException(
          'O ficheiro seleccionado non é un arquivo .pkpass ou ZIP válido');
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
      throw const FormatException('O ficheiro .pkpass non contén pass.json');
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

    // 1. Origin & Destination
    final originKeys = [
      'origin',
      'origen',
      'from',
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
    final primaryOriginField = _findStationField(primaryFields, originKeys);
    final primaryDestinationField =
        _findStationField(primaryFields, destinationKeys);
    final hasNamedEndpoints =
        primaryOriginField != null || primaryDestinationField != null;
    final originField = primaryOriginField ??
        _findStationField(allFields, originKeys) ??
        (!hasNamedEndpoints && primaryFields.isNotEmpty
            ? primaryFields[0]
            : null);
    final destField = primaryDestinationField ??
        _findStationField(allFields, destinationKeys) ??
        (!hasNamedEndpoints && primaryFields.length > 1
            ? primaryFields[1]
            : null);
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

    final productRaw = _normalizeTrainProduct(
      _findValue([
            ...secondaryFields,
            ...auxiliaryFields,
            ...headerFields
          ], [
            'producto',
            'product',
            'servicio',
            'tipotren',
            'comercial',
            'categoria'
          ]) ??
          _findValue(allFields,
              ['producto', 'product', 'servicio', 'tipotren', 'comercial']) ??
          _inferTrainType(operator),
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
        'Estándar';

    // 5. Platform (Vía)
    final platform = _findValue(
            [...headerFields, ...secondaryFields, ...auxiliaryFields],
            ['via', 'vía', 'platform', 'anden', 'andén']) ??
        _findValue(allFields, ['via', 'vía', 'platform']);

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
    final expirationDateStr = json['expirationDate']?.toString();
    final dateField = _findValue(allFields, ['fecha', 'date', 'data']);
    final timeDepField =
        _findValue(auxiliaryFields, ['salida', 'horasalida', 'departure']) ??
            _findValue(allFields, ['salida', 'horasalida', 'departure']);
    final timeArrField =
        _findValue(auxiliaryFields, ['llegada', 'horallegada', 'arrival']) ??
            _findValue(allFields, ['llegada', 'horallegada', 'arrival']);

    final departureTime = _parseToMadridTime(
      isoString: relevantDateStr,
      dateFallback: dateField,
      timeFallback: timeDepField,
      defaultOffsetHours: 2,
    );

    final arrivalTime = _parseToMadridTime(
      isoString: expirationDateStr,
      dateFallback: dateField,
      timeFallback: timeArrField,
      defaultOffsetHours: 4,
      referenceTime: departureTime,
    );

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

  /// Parses date & time accurately into Europe/Madrid local time (CET UTC+1 / CEST UTC+2).
  static DateTime _parseToMadridTime({
    String? isoString,
    String? dateFallback,
    String? timeFallback,
    required int defaultOffsetHours,
    DateTime? referenceTime,
  }) {
    if (isoString != null) {
      final parsed = DateTime.tryParse(isoString);
      if (parsed != null) {
        // If parsed is in UTC, adjust to Europe/Madrid offset
        if (parsed.isUtc) {
          final isSummerTime = _isMadridSummerTime(parsed);
          final madridOffset = Duration(hours: isSummerTime ? 2 : 1);
          final madrid = parsed.add(madridOffset);
          return DateTime(madrid.year, madrid.month, madrid.day, madrid.hour,
              madrid.minute);
        }
        return parsed;
      }
    }

    // Try combining dateFallback (e.g. "2026-11-23" or "23/11/2026") and timeFallback ("14:30")
    if (dateFallback != null && timeFallback != null) {
      final combined = _combineDateAndTime(dateFallback, timeFallback);
      if (combined != null) return combined;
    }

    final base = referenceTime ?? DateTime.now();
    return base.add(Duration(hours: defaultOffsetHours));
  }

  static bool _isMadridSummerTime(DateTime utc) {
    // Last Sunday of March to Last Sunday of October
    final year = utc.year;
    final lastSundayMarch = DateTime.utc(
        year, 3, 31 - ((DateTime.utc(year, 3, 31).weekday) % 7), 1);
    final lastSundayOctober = DateTime.utc(
        year, 10, 31 - ((DateTime.utc(year, 10, 31).weekday) % 7), 1);
    return utc.isAfter(lastSundayMarch) && utc.isBefore(lastSundayOctober);
  }

  static DateTime? _combineDateAndTime(String dateStr, String timeStr) {
    try {
      int year = DateTime.now().year;
      int month = DateTime.now().month;
      int day = DateTime.now().day;

      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
          year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          year = int.parse(parts[0]);
          month = int.parse(parts[1]);
          day = int.parse(parts[2].substring(0, 2));
        }
      }

      int hour = 12;
      int minute = 0;
      final cleanTime = timeStr.replaceAll(RegExp(r'[^0-9:]'), '');
      if (cleanTime.contains(':')) {
        final tParts = cleanTime.split(':');
        hour = int.parse(tParts[0]);
        minute = int.parse(tParts[1]);
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static String _extractStationCode(String stationName) {
    final clean = stationName.toUpperCase();
    if (clean.contains('OURENSE') || clean.contains('ORENSE')) return 'OUR';
    if (clean.contains('SANTIAGO')) return 'SCQ';
    if (clean.contains('CORUÑA') || clean.contains('CORUNA')) return 'LC';
    if (clean.contains('CHAMART') || clean.contains('CHAMARTIN')) {
      return 'MAD-CH';
    }
    if (clean.contains('ATOCHA')) {
      return 'MAD-AT';
    }
    if (clean.contains('SANTS') || clean.contains('BARCELONA')) {
      return 'BCN';
    }
    if (clean.contains('VIGO')) {
      return 'VGO';
    }
    if (clean.contains('PONTEVEDRA')) {
      return 'PO';
    }
    if (clean.contains('LUGO')) {
      return 'LU';
    }
    if (clean.contains('ZAMORA')) {
      return 'ZA';
    }
    if (clean.contains('LEON') || clean.contains('LEÓN')) return 'LE';
    return clean.length >= 3 ? clean.substring(0, 3) : clean;
  }

  static (String, String) _stationNameAndCode(Map<String, dynamic>? field) {
    if (field == null) return ('', '');
    final label = field['label']?.toString().trim() ?? '';
    final value = field['value']?.toString().trim() ?? '';
    if (label.isEmpty && value.isEmpty) return ('', '');

    if (_isGenericStationLabel(label)) {
      final name = value;
      final code =
          _looksLikeStationCode(name) ? name : _extractStationCode(name);
      return (_stationNameForCode(code, name), code);
    }

    final labelIsCode = _looksLikeStationCode(label);
    final valueIsCode = _looksLikeStationCode(value);
    if (valueIsCode && !labelIsCode) return (label, value);
    if (labelIsCode && !valueIsCode) return (value, label);

    if (valueIsCode) return (label.isNotEmpty ? label : value, value);
    if (labelIsCode) return (value.isNotEmpty ? value : label, label);
    return (value.isNotEmpty ? value : label, '');
  }

  static bool _isGenericStationLabel(String label) {
    final normalized = label.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return const {
      'ORIGEN',
      'DESTINO',
      'SALIDA',
      'LLEGADA',
      'ORIGIN',
      'DESTINATION',
    }.contains(normalized);
  }

  static String _stationNameForCode(String code, String fallback) {
    switch (code.toUpperCase()) {
      case 'OUR':
      case '22100':
        return 'Ourense';
      case 'SCQ':
      case '31400':
        return 'Santiago de Compostela';
      case 'LC':
      case '15200':
        return 'A Coruña';
      case 'MAD-CH':
      case '10000':
        return 'Madrid-Chamartín-Clara Campoamor';
      case 'MAD-AT':
      case '60000':
        return 'Madrid-Puerta de Atocha';
      case 'BCN':
      case '71801':
        return 'Barcelona-Sants';
      case '22308':
        return 'Vigo-Urzáiz';
      case '22300':
        return 'Vigo-Guixar';
      case '22200':
        return 'Pontevedra';
      case '20200':
        return 'Lugo';
      case '20100':
        return 'Monforte de Lemos';
      case '15100':
        return 'León';
      case '30100':
        return 'Zamora';
      default:
        return fallback;
    }
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
    final normalizedMatches = matchKeys
        .map((key) => key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .toSet();
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
      final value = field['value']?.toString().trim() ?? '';
      final isStationField = normalizedMatches.any(
        (match) => key == match || key.contains(match) || label == match,
      );
      if (isStationField &&
          value.isNotEmpty &&
          !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) {
        return field;
      }
    }
    return null;
  }

  static String _normalizeTrainProduct(String raw) {
    final compact = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[._-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (compact.isEmpty) return '';
    if (compact.contains('REGIONAL') && compact.contains('EXP')) {
      return 'REG.EXP.';
    }
    if (RegExp(r'\bCERCAN').hasMatch(compact)) return 'CERCANÍAS';
    if (RegExp(r'\bTRENHOTEL\b').hasMatch(compact)) return 'TRENHOTEL';
    if (RegExp(r'\bEUROMED\b').hasMatch(compact)) return 'EUROMED';
    if (RegExp(r'\bOUIGO\b|\bOUI\b').hasMatch(compact)) return 'OUIGO';
    if (RegExp(r'\bIRYO\b|\bIRY\b').hasMatch(compact)) return 'IRYO';
    if (RegExp(r'\bINTERCITY\b|\bICITY\b|\bINTC\b').hasMatch(compact)) {
      return 'INTERCITY';
    }
    if (RegExp(r'\bAVLO\b').hasMatch(compact)) return 'AVLO';
    if (RegExp(r'\bALVIA\b').hasMatch(compact)) return 'ALVIA';
    if (RegExp(r'\bAVANT\b|\bAVA\b').hasMatch(compact)) return 'AVANT';
    if (RegExp(r'\bAVE\b|\bAVE624\b').hasMatch(compact)) return 'AVE';
    if (RegExp(r'\bMD\b').hasMatch(compact)) return 'MD';
    if (compact.contains('REGIONAL')) return 'REGIONAL';
    return compact;
  }

  static String _inferTrainType(RailOperator operator) {
    switch (operator) {
      case RailOperator.renfe:
      case RailOperator.renfeAve:
      case RailOperator.renfeAvant:
      case RailOperator.renfeIntercity:
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
