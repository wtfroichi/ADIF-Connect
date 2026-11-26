import 'dart:convert';

import '../core/constants/adif_stations.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/operator_themes.dart';
import '../models/ticket_model.dart';

abstract final class GoogleWalletJwtParser {
  static List<TicketModel> parseSaveLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const FormatException(AppStrings.walletLinkInvalid);
    }

    final pathToken = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final queryToken = uri.queryParameters['jwt'] ??
        uri.queryParameters['token'] ??
        uri.queryParameters['saveToken'];
    final token = queryToken?.isNotEmpty == true ? queryToken! : pathToken;
    if (token.isEmpty) {
      throw const FormatException(AppStrings.walletLinkInvalid);
    }

    final parts = token.split('.');
    final encodedPayload = parts.length >= 2 ? parts[1] : token;
    final payloadBytes = base64Url.decode(
      base64Url.normalize(encodedPayload),
    );
    final payload = jsonDecode(utf8.decode(payloadBytes));
    if (payload is! Map) {
      throw const FormatException(AppStrings.walletLinkInvalid);
    }

    final objects = <Map<String, dynamic>>[];
    final transit = payload['transitObjects'];
    if (transit is List) {
      for (final item in transit.whereType<Map>()) {
        objects.add(item.cast<String, dynamic>());
      }
    }
    final generic = payload['genericObjects'];
    if (generic is List) {
      for (final item in generic.whereType<Map>()) {
        objects.add(item.cast<String, dynamic>());
      }
    }
    if (objects.isEmpty) {
      throw const FormatException(AppStrings.walletLinkInvalid);
    }

    final tickets = <TicketModel>[];
    for (final object in objects) {
      final ticket = _ticketFromObject(object);
      if (ticket != null) tickets.add(ticket);
    }
    return tickets;
  }

  static TicketModel? _ticketFromObject(Map<String, dynamic> object) {
    final originText =
        _string(object, ['originName', 'origin', 'departureStation']) ??
            _nestedString(object, ['originAndDestination', 'originName']);
    final destinationText =
        _string(object, ['destinationName', 'destination', 'arrivalStation']) ??
            _nestedString(object, ['originAndDestination', 'destinationName']);
    if (originText == null || destinationText == null) return null;

    final origin =
        AdifStations.byName(originText) ?? AdifStations.byCode(originText);
    final destination = AdifStations.byName(destinationText) ??
        AdifStations.byCode(destinationText);
    if (origin == null || destination == null) return null;

    final departureText = _string(object, [
          'departureDateTime',
          'departureTime',
          'validTimeStart',
        ]) ??
        _nestedString(object, ['originAndDestination', 'departureDateTime']);
    final arrivalText = _string(object, [
          'arrivalDateTime',
          'arrivalTime',
          'validTimeEnd',
        ]) ??
        _nestedString(object, ['originAndDestination', 'arrivalDateTime']);
    final departure = DateTime.tryParse(departureText ?? '');
    final arrival = DateTime.tryParse(arrivalText ?? '');
    if (departure == null || arrival == null) return null;

    final trainNumber = _string(object, [
          'trainNumber',
          'tripNumber',
          'vehicleId',
        ]) ??
        '';
    final trainType = _string(object, [
          'fareName',
          'serviceType',
          'tripType',
          'class',
        ]) ??
        '';
    final operator = _operatorForObject(object);
    final normalizedType = trainType.isEmpty
        ? 'RENFE'
        : OperatorThemes.normalizeRenfeService(trainType);
    final ticketNumber = _string(object, [
      'ticketNumber',
      'passengerNumber',
      'serialNumber',
      'objectId',
    ]);
    final coach = _string(object, ['coach', 'carriage', 'seatCarriage']) ?? '';
    final seat = _string(object, ['seat', 'seatLabel', 'seatNumber']) ?? '';
    final passenger = _string(object, [
          'passengerName',
          'passenger',
          'cardTitle',
        ]) ??
        '';
    final locator = _string(object, [
          'bookingReference',
          'localizer',
          'locator',
          'pnr',
        ]) ??
        '';

    final barcode = ticketNumber == null
        ? null
        : TicketBarcode(
            message: ticketNumber,
            format: BarcodeType.aztec,
            rawFormat: 'PKBarcodeFormatAztec',
          );

    return TicketModel(
      id: 'wallet-${ticketNumber ?? (locator.isNotEmpty ? locator : object.hashCode)}',
      operator: operator,
      origin: origin.name,
      originCode: origin.adifCode,
      destination: destination.name,
      destinationCode: destination.adifCode,
      departureTime: departure,
      arrivalTime: arrival,
      trainNumber: trainNumber,
      trainType: normalizedType,
      coach: coach,
      seat: seat,
      seatClass: trainType,
      platform: null,
      passengerName: passenger,
      ticketNumber: ticketNumber,
      bookingReference: locator,
      barcode: barcode,
    );
  }

  static RailOperator _operatorForObject(Map<String, dynamic> object) {
    final text = jsonEncode(object).toLowerCase();
    if (text.contains('ouigo')) return RailOperator.ouigo;
    if (text.contains('iryo')) return RailOperator.iryo;
    if (text.contains('renfe')) return RailOperator.renfe;
    return RailOperator.unknown;
  }

  static String? _string(Map<String, dynamic> object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _nestedString(
    Map<String, dynamic> object,
    List<String> keys,
  ) {
    Map<String, dynamic>? current = object;
    for (final key in keys) {
      final value = current?[key];
      if (value is Map) {
        current = value.cast<String, dynamic>();
      } else if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      } else {
        return null;
      }
    }
    return null;
  }
}
