import 'app_strings.dart';

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

abstract final class AdifStations {
  static const List<StationInfo> all = [
    StationInfo(
        code: '22100', name: 'Ourense', province: 'Ourense', adifCode: '22100'),
    StationInfo(
        code: '31400',
        name: 'Santiago de Compostela',
        province: 'A Coruña',
        adifCode: '31400'),
    StationInfo(
        code: '31412',
        name: 'A Coruña',
        province: 'A Coruña',
        adifCode: '31412'),
    StationInfo(
        code: '22308',
        name: 'Vigo-Urzáiz',
        province: 'Pontevedra',
        adifCode: '22308'),
    StationInfo(
        code: '22300',
        name: 'Vigo-Guixar',
        province: 'Pontevedra',
        adifCode: '22300'),
    StationInfo(
        code: '22200',
        name: 'Pontevedra',
        province: 'Pontevedra',
        adifCode: '22200'),
    StationInfo(
        code: '22204',
        name: 'Vilagarcía de Arousa',
        province: 'Pontevedra',
        adifCode: '22204'),
    StationInfo(
        code: '31308',
        name: 'Padrón-Barbanza',
        province: 'A Coruña',
        adifCode: '31308'),
    StationInfo(
        code: '22303',
        name: 'Redondela',
        province: 'Pontevedra',
        adifCode: '22303'),
    StationInfo(
        code: '22301',
        name: 'O Porriño',
        province: 'Pontevedra',
        adifCode: '22301'),
    StationInfo(
        code: '22112',
        name: 'Guillarei',
        province: 'Pontevedra',
        adifCode: '22112'),
    StationInfo(
        code: '22104',
        name: 'Ribadavia',
        province: 'Ourense',
        adifCode: '22104'),
    StationInfo(
        code: '31206',
        name: 'O Carballiño',
        province: 'Ourense',
        adifCode: '31206'),
    StationInfo(
        code: '31212',
        name: 'Lalín',
        province: 'Pontevedra',
        adifCode: '31212'),
    StationInfo(
        code: '20200', name: 'Lugo', province: 'Lugo', adifCode: '20200'),
    StationInfo(
        code: '20105', name: 'Sarria', province: 'Lugo', adifCode: '20105'),
    StationInfo(
        code: '20100',
        name: 'Monforte de Lemos',
        province: 'Lugo',
        adifCode: '20100'),
    StationInfo(
        code: '20006',
        name: 'O Barco de Valdeorras',
        province: 'Ourense',
        adifCode: '20006'),
    StationInfo(
        code: '20004',
        name: 'A Rúa-Petín',
        province: 'Ourense',
        adifCode: '20004'),
    StationInfo(
        code: '31500', name: 'Ferrol', province: 'A Coruña', adifCode: '31500'),
    StationInfo(
        code: '31418',
        name: 'Betanzos',
        province: 'A Coruña',
        adifCode: '31418'),
    StationInfo(
        code: '05440',
        name: 'Ortigueira',
        province: 'A Coruña',
        adifCode: '05440'),
    StationInfo(
        code: '05425', name: 'Viveiro', province: 'Lugo', adifCode: '05425'),
    StationInfo(
        code: '05400', name: 'Ribadeo', province: 'Lugo', adifCode: '05400'),
    StationInfo(
        code: '17000',
        name: 'Madrid-Chamartín',
        province: 'Madrid',
        adifCode: '17000'),
    StationInfo(
        code: '18000',
        name: 'Madrid-Puerta de Atocha',
        province: 'Madrid',
        adifCode: '18000'),
    StationInfo(
        code: '71801',
        name: 'Barcelona-Sants',
        province: 'Barcelona',
        adifCode: '71801'),
    StationInfo(
        code: '03216',
        name: 'Valencia Joaquín Sorolla',
        province: 'Valencia',
        adifCode: '03216'),
    StationInfo(
        code: '51003',
        name: 'Sevilla-Santa Justa',
        province: 'Sevilla',
        adifCode: '51003'),
    StationInfo(
        code: '54413',
        name: 'Málaga-María Zambrano',
        province: 'Málaga',
        adifCode: '54413'),
    StationInfo(
        code: '70600',
        name: 'Zaragoza-Delicias',
        province: 'Zaragoza',
        adifCode: '70600'),
    StationInfo(
        code: '10600',
        name: 'Valladolid-Campo Grande',
        province: 'Valladolid',
        adifCode: '10600'),
    StationInfo(
        code: '15100', name: 'León', province: 'León', adifCode: '15100'),
    StationInfo(
        code: '30100', name: 'Zamora', province: 'Zamora', adifCode: '30100'),
    StationInfo(
        code: '08004',
        name: 'Segovia-Guiomar',
        province: 'Segovia',
        adifCode: '08004'),
    StationInfo(
        code: '08240',
        name: 'Medina del Campo AV',
        province: 'Valladolid',
        adifCode: '08240'),
    StationInfo(
        code: '30200',
        name: 'Sanabria AV',
        province: 'Zamora',
        adifCode: '30200'),
    StationInfo(
        code: '30204',
        name: 'A Gudiña-Porta de Galicia',
        province: 'Ourense',
        adifCode: '30204'),
    StationInfo(
        code: '60911',
        name: 'Alicante',
        province: 'Alicante',
        adifCode: '60911'),
    StationInfo(
        code: '61200', name: 'Murcia', province: 'Murcia', adifCode: '61200'),
    StationInfo(
        code: '13200',
        name: 'Bilbao-Abando',
        province: 'Bizkaia',
        adifCode: '13200'),
    StationInfo(
        code: '11511',
        name: 'Donostia-San Sebastián',
        province: 'Gipuzkoa',
        adifCode: '11511'),
    StationInfo(
        code: '11208',
        name: 'Vitoria-Gasteiz',
        province: 'Araba',
        adifCode: '11208'),
    StationInfo(
        code: '15211', name: 'Oviedo', province: 'Asturias', adifCode: '15211'),
    StationInfo(
        code: '15410', name: 'Xixón', province: 'Asturias', adifCode: '15410'),
    StationInfo(
        code: '14223',
        name: 'Santander',
        province: 'Cantabria',
        adifCode: '14223'),
    StationInfo(
        code: '11014',
        name: 'Burgos-Rosa Manzano',
        province: 'Burgos',
        adifCode: '11014'),
    StationInfo(
        code: '14100',
        name: 'Palencia',
        province: 'Palencia',
        adifCode: '14100'),
    StationInfo(
        code: '30000',
        name: 'Salamanca',
        province: 'Salamanca',
        adifCode: '30000'),
    StationInfo(
        code: '50500', name: 'Córdoba', province: 'Córdoba', adifCode: '50500'),
    StationInfo(
        code: '05000', name: 'Granada', province: 'Granada', adifCode: '05000'),
    StationInfo(
        code: '51405', name: 'Cádiz', province: 'Cádiz', adifCode: '51405'),
    StationInfo(
        code: '43019', name: 'Huelva', province: 'Huelva', adifCode: '43019'),
    StationInfo(
        code: '37606', name: 'Badajoz', province: 'Badajoz', adifCode: '37606'),
    StationInfo(
        code: '35400', name: 'Cáceres', province: 'Cáceres', adifCode: '35400'),
    StationInfo(
        code: '80100',
        name: 'Pamplona',
        province: 'Navarra',
        adifCode: '80100'),
    StationInfo(
        code: '81100',
        name: 'Logroño',
        province: 'La Rioja',
        adifCode: '81100'),
    StationInfo(
        code: '71500',
        name: 'Tarragona',
        province: 'Tarragona',
        adifCode: '71500'),
    StationInfo(
        code: '79300', name: 'Girona', province: 'Girona', adifCode: '79300'),
    StationInfo(
        code: '79316',
        name: 'Figueres-Vilafant',
        province: 'Girona',
        adifCode: '79316'),
    StationInfo(
        code: '78400',
        name: 'Lleida-Pirineus',
        province: 'Lleida',
        adifCode: '78400'),
    StationInfo(
        code: '65300',
        name: 'Castelló',
        province: 'Castelló',
        adifCode: '65300'),
    StationInfo(
        code: '60600',
        name: 'Albacete-Los Llanos',
        province: 'Albacete',
        adifCode: '60600'),
    StationInfo(
        code: '03208',
        name: 'Cuenca-Fernando Zóbel',
        province: 'Cuenca',
        adifCode: '03208'),
    StationInfo(
        code: '37200',
        name: 'Ciudad Real',
        province: 'Ciudad Real',
        adifCode: '37200'),
    StationInfo(
        code: '37300',
        name: 'Puertollano',
        province: 'Ciudad Real',
        adifCode: '37300'),
    StationInfo(
        code: '92103', name: 'Toledo', province: 'Toledo', adifCode: '92103'),
  ];

  static const Map<String, String> _codeAliases = {
    '08223': '22308',
    'OUR': '22100',
    'SCQ': '31400',
    'LC': '31412',
    'VGO-U': '22308',
    'VGO-G': '22300',
    'PO': '22200',
    'LU': '20200',
    'ML': '20100',
    'MAD-CH': '17000',
    'MAD-AT': '18000',
    'BCN': '71801',
    'LE': '15100',
    'ZA': '30100',
  };

  static StationInfo? byCode(String code) {
    final normalizedCode = code.trim().toUpperCase();
    for (final station in all) {
      if (station.adifCode == normalizedCode ||
          station.code == normalizedCode) {
        return station;
      }
    }
    final canonicalCode = _codeAliases[normalizedCode];
    if (canonicalCode != null) {
      return all.firstWhere((station) => station.adifCode == canonicalCode);
    }
    return null;
  }

  static String resolveName(String codeOrName) {
    final value = codeOrName.trim();
    if (value.isEmpty) return value;
    return byCode(value)?.name ??
        byName(value)?.name ??
        (RegExp(r'^\d+$').hasMatch(value)
            ? AppStrings.stationUnknownName
            : value);
  }

  static List<StationInfo> search(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return all;
    return all.where((station) {
      final aliases = _codeAliases.entries
          .where((entry) => entry.value == station.adifCode)
          .map((entry) => entry.key);
      return [
        station.name,
        station.province,
        station.code,
        station.adifCode,
        ...aliases,
      ].any((term) => _normalize(term).contains(normalizedQuery));
    }).toList();
  }

  static StationInfo? byName(String name) {
    final normalized = _normalize(name);
    for (final station in all) {
      if (_normalize(station.name) == normalized) return station;
    }
    if (normalized.contains('santiago')) return byCode('31400');
    if (normalized.contains('acoruna') || normalized.contains('coruna')) {
      return byCode('31412');
    }
    if (normalized.contains('ourense') || normalized.contains('orense')) {
      return byCode('22100');
    }
    if (normalized.contains('vigourzaiz')) return byCode('22308');
    if (normalized.contains('madridchamart')) return byCode('17000');
    if (normalized.contains('atocha')) return byCode('18000');
    return null;
  }

  static String normalize(String value) => _normalize(value);

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}
