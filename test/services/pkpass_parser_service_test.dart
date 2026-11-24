import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/models/ticket_model.dart';
import 'package:adif_connect/services/pkpass_parser_service.dart';

Uint8List _pkpassBytes(
  Map<String, dynamic> boardingPass, {
  String relevantDate = '2027-01-15T10:00+01:00',
}) {
  final auxiliaryFields =
      List<Map<String, dynamic>>.from(boardingPass['auxiliaryFields'] ?? [])
        ..addAll([
          {'key': 'departure', 'label': 'Saída', 'value': '10:00'},
          {'key': 'arrival', 'label': 'Chegada', 'value': '11:00'},
        ]);
  final content = utf8.encode(jsonEncode({
    'passTypeIdentifier': 'pass.com.renfe.ticket',
    'organizationName': 'Renfe',
    'serialNumber': 'TEST-123',
    'relevantDate': relevantDate,
    'boardingPass': {
      ...boardingPass,
      'auxiliaryFields': auxiliaryFields,
    },
  }));
  final archive = Archive()
    ..addFile(ArchiveFile('pass.json', content.length, content));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  group('PkpassParserService Renfe stations', () {
    test('uses the value for generic station headings', () {
      final ticket = PkpassParserService.parse(_pkpassBytes({
        'primaryFields': [
          {'key': 'origin', 'label': 'ORIGEN', 'value': 'OURENSE'},
          {
            'key': 'destination',
            'label': 'DESTINO',
            'value': 'MADRID-CHAMARTÍN-CLARA CAMPOAMOR',
          },
        ],
      }));

      expect(ticket.origin, 'Ourense');
      expect(ticket.originCode, '22100');
      expect(ticket.destination, 'Madrid-Chamartín');
      expect(ticket.destinationCode, '17000');
    });

    test('uses a long station label when value contains its short code', () {
      final ticket = PkpassParserService.parse(_pkpassBytes({
        'primaryFields': [
          {'key': 'origin', 'label': 'OURENSE', 'value': 'OUR'},
          {
            'key': 'destination',
            'label': 'SANTIAGO DE COMPOSTELA',
            'value': 'SCQ'
          },
        ],
      }));

      expect(ticket.origin, 'Ourense');
      expect(ticket.originCode, 'OUR');
      expect(ticket.destination, 'Santiago de Compostela');
      expect(ticket.destinationCode, 'SCQ');
    });

    test('resolves generic headings containing known short station codes', () {
      final ticket = PkpassParserService.parse(_pkpassBytes({
        'primaryFields': [
          {'key': 'origin', 'label': 'ORIGEN', 'value': 'OUR'},
          {'key': 'destination', 'label': 'DESTINO', 'value': 'SCQ'},
        ],
      }));

      expect(ticket.origin, 'Ourense');
      expect(ticket.originCode, 'OUR');
      expect(ticket.destination, 'Santiago de Compostela');
      expect(ticket.destinationCode, 'SCQ');
    });

    test('uses the first two primary fields when station keys are absent', () {
      final ticket = PkpassParserService.parse(_pkpassBytes({
        'primaryFields': [
          {
            'key': 'boardingTime',
            'label': 'ESTACIÓN DE ORIXE DESCOÑECIDA',
            'value': '10:00',
          },
          {
            'key': 'arrivalTime',
            'label': 'ESTACIÓN DE DESTINO DESCOÑECIDA',
            'value': '11:00',
          },
        ],
      }));

      expect(ticket.origin, 'ESTACIÓN DE ORIXE DESCOÑECIDA');
      expect(ticket.destination, 'ESTACIÓN DE DESTINO DESCOÑECIDA');
    });

    test('finds named station fields outside primaryFields', () {
      final ticket = PkpassParserService.parse(_pkpassBytes({
        'primaryFields': [
          {'key': 'train', 'label': 'TREN', 'value': '00605'},
        ],
        'secondaryFields': [
          {'key': 'origin', 'label': 'ORIGEN', 'value': 'OURENSE'},
          {'key': 'destination', 'label': 'DESTINO', 'value': 'SANTIAGO'},
        ],
      }));

      expect(ticket.origin, 'Ourense');
      expect(ticket.destination, 'Santiago de Compostela');
      expect(ticket.destinationCode, '31400');
    });

    test(
        'parses the Renfe AVANT Wallet field layout without misusing date or via',
        () {
      final content = utf8.encode(jsonEncode({
        'passTypeIdentifier': 'pass.com.renfe.ticket',
        'organizationName': 'Renfe',
        'serialNumber': 'TEST-456',
        'relevantDate': '2027-02-11T09:10+01:00',
        'barcode': {
          'format': 'PKBarcodeFormatAztec',
          'message': 'barcode-payload',
        },
        'boardingPass': {
          'primaryFields': [
            {'key': 'boardingTime', 'label': 'A CORUÑA', 'value': '09:10'},
            {
              'key': 'destino',
              'label': 'VIGO-URZÁIZ',
              'value': '10:03',
            },
          ],
          'secondaryFields': [
            {'key': 'localizador', 'label': 'Localizador', 'value': 'XYZ789'},
          ],
          'auxiliaryFields': [
            {'key': 'tren', 'label': 'Tren AVANT', 'value': '04184'},
            {'key': 'coche', 'label': 'Coche', 'value': '004'},
            {'key': 'asiento', 'label': 'Asiento', 'value': '012'},
            {'key': 'clasefrontal', 'label': 'Clase', 'value': 'Turista'},
          ],
          'headerFields': [
            {
              'key': 'destinofecha',
              'label': 'Viaxe a: VIGO-URZÁIZ',
              'value': '11/02/2027',
            },
          ],
        },
      }));
      final archive = Archive()
        ..addFile(ArchiveFile('pass.json', content.length, content));

      final ticket = PkpassParserService.parse(
          Uint8List.fromList(ZipEncoder().encode(archive)!));

      expect(ticket.origin, 'A Coruña');
      expect(ticket.originCode, '31412');
      expect(ticket.destination, 'Vigo-Urzáiz');
      expect(ticket.destinationCode, '22308');
      expect(ticket.departureTime, DateTime(2027, 2, 11, 9, 10));
      expect(ticket.arrivalTime, DateTime(2027, 2, 11, 10, 3));
      expect(ticket.trainType, 'AVANT');
      expect(ticket.trainNumber, '04184');
      expect(ticket.coach, '004');
      expect(ticket.seat, '012');
      expect(ticket.seatClass, 'Turista');
      expect(ticket.platform, isNull);
      expect(ticket.bookingReference, 'XYZ789');
      expect(ticket.barcode?.format, BarcodeType.aztec);
    });

    test('converts an explicitly offset summer date to Madrid calendar time',
        () {
      final ticket = PkpassParserService.parse(
        _pkpassBytes(
          {
            'primaryFields': [
              {'key': 'origin', 'label': 'ORIXE', 'value': 'OURENSE'},
              {'key': 'destination', 'label': 'DESTINO', 'value': 'SANTIAGO'},
            ],
          },
          relevantDate: '2027-07-12T23:30:00Z',
        ),
      );

      expect(ticket.departureTime, DateTime(2027, 7, 13, 10));
    });
  });
}
