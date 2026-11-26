import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/core/constants/adif_stations.dart';
import 'package:adif_connect/core/constants/app_strings.dart';
import 'package:adif_connect/core/constants/station_coordinates.dart';

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

  test('resolves Renfe PDF station abbreviations', () {
    expect(AdifStations.resolveName('SANTIAGO C'), 'Santiago de Compostela');
    expect(AdifStations.resolveName('SANTIAGO DE C'), 'Santiago de Compostela');
    expect(AdifStations.resolveName('A CORUNA'), 'A Coruña');
    expect(AdifStations.resolveName('VIGO GUIXAR'), 'Vigo-Guixar');
    expect(AdifStations.resolveName('VIGO URZAIZ'), 'Vigo-Urzáiz');
    expect(AdifStations.resolveName('MADRID CHAM'), 'Madrid-Chamartín');
    expect(AdifStations.resolveName('MADRID ATOCH'), 'Madrid-Puerta de Atocha');
    expect(AdifStations.resolveName('BARCELONA SA'), 'Barcelona-Sants');
  });

  test('finds nearest station using station coordinates', () {
    expect(AdifStations.nearestTo(42.8704, -8.5452)?.adifCode, '31400');
    expect(AdifStations.nearestTo(40.4721, -3.6823)?.adifCode, '17000');
    expect(AdifStations.nearestTo(91, 0), isNull);
  });

  test('provides coordinates for every selectable station', () {
    for (final station in AdifStations.all) {
      expect(
        stationCoordinatesByCode.containsKey(station.adifCode),
        isTrue,
        reason: 'Missing coordinates for ${station.name}',
      );
    }
  });
}
