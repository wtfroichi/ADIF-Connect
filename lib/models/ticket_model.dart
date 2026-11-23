import '../core/theme/operator_themes.dart';

enum BarcodeType {
  aztec,
  qrCode,
  pdf417,
  code128,
  unknown,
}

class TicketBarcode {
  final String message;
  final BarcodeType format;
  final String? altText;
  final String? messageEncoding;
  final String? rawFormat;

  const TicketBarcode({
    required this.message,
    this.format = BarcodeType.aztec,
    this.altText,
    this.messageEncoding,
    this.rawFormat,
  });

  factory TicketBarcode.fromJson(Map<String, dynamic> json) {
    final formatStr = json['format']?.toString() ?? '';
    BarcodeType format = BarcodeType.unknown;
    if (formatStr.contains('PKBarcodeFormatAztec') || formatStr == 'aztec') {
      format = BarcodeType.aztec;
    } else if (formatStr.contains('PKBarcodeFormatQR') || formatStr == 'qr') {
      format = BarcodeType.qrCode;
    } else if (formatStr.contains('PKBarcodeFormatPDF417') || formatStr == 'pdf417') {
      format = BarcodeType.pdf417;
    } else if (formatStr.contains('PKBarcodeFormatCode128') || formatStr == 'code128') {
      format = BarcodeType.code128;
    }

    return TicketBarcode(
      message: json['message']?.toString() ?? '',
      format: format,
      altText: json['altText']?.toString(),
      messageEncoding: json['messageEncoding']?.toString(),
      rawFormat: json['format']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'format': format.name,
        if (altText != null) 'altText': altText,
        if (messageEncoding != null) 'messageEncoding': messageEncoding,
        if (rawFormat != null) 'rawFormat': rawFormat,
      };
}

class TicketModel {
  final String id;
  final RailOperator operator;
  final String origin;
  final String originCode;
  final String destination;
  final String destinationCode;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String trainNumber;
  final String trainType; // AVE, Avlo, Alvia, Iryo, etc.
  final String coach;
  final String seat;
  final String seatClass;
  final String? platform;
  final String passengerName;
  final String bookingReference; // Localizador
  final TicketBarcode? barcode;

  const TicketModel({
    required this.id,
    required this.operator,
    required this.origin,
    required this.originCode,
    required this.destination,
    required this.destinationCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.trainNumber,
    required this.trainType,
    required this.coach,
    required this.seat,
    required this.seatClass,
    this.platform,
    required this.passengerName,
    required this.bookingReference,
    this.barcode,
  });

  Duration get travelDuration => arrivalTime.difference(departureTime);

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      operator: RailOperator.values.byName(json['operator'] as String),
      origin: json['origin'] as String,
      originCode: json['originCode'] as String,
      destination: json['destination'] as String,
      destinationCode: json['destinationCode'] as String,
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      trainNumber: json['trainNumber'] as String,
      trainType: json['trainType'] as String,
      coach: json['coach'] as String,
      seat: json['seat'] as String,
      seatClass: json['seatClass'] as String,
      platform: json['platform'] as String?,
      passengerName: json['passengerName'] as String,
      bookingReference: json['bookingReference'] as String,
      barcode: json['barcode'] != null
          ? TicketBarcode.fromJson(json['barcode'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'operator': operator.name,
        'origin': origin,
        'originCode': originCode,
        'destination': destination,
        'destinationCode': destinationCode,
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'trainNumber': trainNumber,
        'trainType': trainType,
        'coach': coach,
        'seat': seat,
        'seatClass': seatClass,
        if (platform != null) 'platform': platform,
        'passengerName': passengerName,
        'bookingReference': bookingReference,
        if (barcode != null) 'barcode': barcode!.toJson(),
      };
}
