import '../models/station_board_model.dart';

abstract class AdifLiveRepository {
  Future<List<StationBoardItem>> getDepartures(String stationCode);
  Future<List<StationBoardItem>> getArrivals(String stationCode);
  List<StationInfo> getAvailableStations();
}

class StationInfo {
  final String code;
  final String name;
  final String province;
  final String adifCode;

  const StationInfo({
    required this.code,
    required this.name,
    required this.province,
    required this.adifCode,
  });
}

class StationCatalog {
  static const List<StationInfo> stations = [
    StationInfo(
        code: 'OUR', name: 'Ourense', province: 'Ourense', adifCode: '22100'),
    StationInfo(
        code: 'SCQ',
        name: 'Santiago de Compostela',
        province: 'A Coruña',
        adifCode: '31400'),
    StationInfo(
        code: 'LC', name: 'A Coruña', province: 'A Coruña', adifCode: '15200'),
    StationInfo(
        code: 'VGO-U',
        name: 'Vigo-Urzáiz',
        province: 'Pontevedra',
        adifCode: '22308'),
    StationInfo(
        code: 'VGO-G',
        name: 'Vigo-Guixar',
        province: 'Pontevedra',
        adifCode: '22300'),
    StationInfo(
        code: 'PO',
        name: 'Pontevedra',
        province: 'Pontevedra',
        adifCode: '22200'),
    StationInfo(code: 'LU', name: 'Lugo', province: 'Lugo', adifCode: '20200'),
    StationInfo(
        code: 'ML',
        name: 'Monforte de Lemos',
        province: 'Lugo',
        adifCode: '20100'),
    StationInfo(
        code: 'MAD-CH',
        name: 'Madrid-Chamartín-Clara Campoamor',
        province: 'Madrid',
        adifCode: '10000'),
    StationInfo(
        code: 'MAD-AT',
        name: 'Madrid-Puerta de Atocha',
        province: 'Madrid',
        adifCode: '60000'),
    StationInfo(
        code: 'BCN',
        name: 'Barcelona-Sants',
        province: 'Barcelona',
        adifCode: '71801'),
    StationInfo(code: 'LE', name: 'León', province: 'León', adifCode: '15100'),
    StationInfo(
        code: 'ZA', name: 'Zamora', province: 'Zamora', adifCode: '30100'),
  ];
}
