import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/core/constants/adif_stations.dart';
import 'package:adif_connect/core/constants/app_strings.dart';

void main() {
  test('resolves ADIF and UIC station codes to station names', () {
    expect(AdifStations.resolveName('08223'), 'Vigo-Urzáiz');
    expect(AdifStations.resolveName('22300'), 'Vigo-Guixar');
    expect(AdifStations.resolveName('31412'), 'A Coruña');
    expect(AdifStations.resolveName('17000'), 'Madrid-Chamartín');
    expect(AdifStations.resolveName('08224'), AppStrings.stationUnknownName);
  });

  test('searches station names without accents and includes station codes', () {
    expect(
      AdifStations.search('coruna').map((station) => station.name),
      contains('A Coruña'),
    );
    expect(
      AdifStations.search('vigo').map((station) => station.name),
      containsAll(['Vigo-Urzáiz', 'Vigo-Guixar']),
    );
    expect(
      AdifStations.search('08223').map((station) => station.name),
      contains('Vigo-Urzáiz'),
    );
  });
}
