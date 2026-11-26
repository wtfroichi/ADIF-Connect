import 'package:flutter_test/flutter_test.dart';

import 'package:anden_libre/models/station_board_model.dart';

void main() {
  test('normalizes missing and invalid platform values', () {
    for (final value in [
      '0',
      '00',
      '0.0',
      '-1',
      '',
      '-',
      '--',
      '—',
      'null',
      'Por asignar',
      '  ',
    ]) {
      expect(StationBoardItem.normalizePlatform(value), isNull);
    }

    expect(StationBoardItem.normalizePlatform(' 4 '), '4');
  });
}
