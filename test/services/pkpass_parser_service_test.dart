import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/services/pkpass_parser_service.dart';

Uint8List _pkpassBytes(Map<String, dynamic> boardingPass) {
  final content = utf8.encode(jsonEncode({
    'passTypeIdentifier': 'pass.com.renfe.ticket',
    'organizationName': 'Renfe',
    'serialNumber': 'TEST-123',
    'boardingPass': boardingPass,
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
      expect(ticket.originCode, 'OUR');
      expect(ticket.destination, 'Madrid-Chamartín-Clara Campoamor');
      expect(ticket.destinationCode, 'MAD-CH');
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

      expect(ticket.origin, 'OURENSE');
      expect(ticket.originCode, 'OUR');
      expect(ticket.destination, 'SANTIAGO DE COMPOSTELA');
      expect(ticket.destinationCode, 'SCQ');
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
      expect(ticket.destinationCode, 'SCQ');
    });
  });
}
