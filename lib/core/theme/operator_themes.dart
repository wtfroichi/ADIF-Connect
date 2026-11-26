import 'package:flutter/material.dart';

/// Supported rail operators.
enum RailOperator {
  renfe,
  renfeAvlo,
  renfeAve,
  renfeAvant,
  renfeAlvia,
  renfeIntercity,
  renfeMd,
  renfeCercanias,
  renfeRegional,
  adif,
  iryo,
  ouigo,
  unknown,
}

/// Dynamic theme styling for each rail operator.
@immutable
class OperatorStyle {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color badgeBackground;
  final Color badgeText;

  const OperatorStyle({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.badgeBackground,
    required this.badgeText,
  });
}

/// Extensible operator palettes with exact corporate colors.
abstract final class OperatorThemes {
  static const Map<RailOperator, OperatorStyle> registry = {
    // General Renfe identity.
    RailOperator.renfe: OperatorStyle(
      name: 'RENFE',
      primary: Color(0xFF680A51),
      secondary: Color(0xFF8E136F),
      accent: Color(0xFFE20074),
      cardBackground: Color(0x2E680A51),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFE5C8DF),
      badgeBackground: Color(0xFF680A51),
      badgeText: Color(0xFFFFFFFF),
    ),

    RailOperator.renfeAvlo: OperatorStyle(
      name: 'RENFE AVLO',
      primary: Color(0xFF0B132B),
      secondary: Color(0xFF00B4D8),
      accent: Color(0xFF00B4D8),
      cardBackground: Color(0x330B132B),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFC7F4FA),
      badgeBackground: Color(0xFF0B132B),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeAve: OperatorStyle(
      name: 'RENFE AVE',
      primary: Color(0xFF0B132B),
      secondary: Color(0xFF1C3D6E),
      accent: Color(0xFF1C3D6E),
      cardBackground: Color(0x330B132B),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD8E2F0),
      badgeBackground: Color(0xFF0B132B),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeAvant: OperatorStyle(
      name: 'RENFE AVANT',
      primary: Color(0xFF0B132B),
      secondary: Color(0xFF1C3D6E),
      accent: Color(0xFF1C3D6E),
      cardBackground: Color(0x330B132B),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD8E2F0),
      badgeBackground: Color(0xFF0B132B),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeIntercity: OperatorStyle(
      name: 'RENFE INTERCITY',
      primary: Color(0xFF680A51),
      secondary: Color(0xFF8E136F),
      accent: Color(0xFF8E136F),
      cardBackground: Color(0x33680A51),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFECC2DF),
      badgeBackground: Color(0xFF680A51),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeAlvia: OperatorStyle(
      name: 'RENFE INTERCITY',
      primary: Color(0xFF680A51),
      secondary: Color(0xFF8E136F),
      accent: Color(0xFF8E136F),
      cardBackground: Color(0x33680A51),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFECC2DF),
      badgeBackground: Color(0xFF680A51),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeMd: OperatorStyle(
      name: 'RENFE REGIONAL',
      primary: Color(0xFF680A51),
      secondary: Color(0xFF8E136F),
      accent: Color(0xFF8E136F),
      cardBackground: Color(0x33680A51),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFECC2DF),
      badgeBackground: Color(0xFF680A51),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeCercanias: OperatorStyle(
      name: 'RENFE CERCANÍAS',
      primary: Color(0xFFEF3340),
      secondary: Color(0xFFC81D25),
      accent: Color(0xFFC81D25),
      cardBackground: Color(0x33EF3340),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFD8DB),
      badgeBackground: Color(0xFFEF3340),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeRegional: OperatorStyle(
      name: 'RENFE REGIONAL',
      primary: Color(0xFF680A51),
      secondary: Color(0xFF8E136F),
      accent: Color(0xFF8E136F),
      cardBackground: Color(0x33680A51),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFECC2DF),
      badgeBackground: Color(0xFF680A51),
      badgeText: Color(0xFFFFFFFF),
    ),

    // ADIF Infrastructure & Station Screens (Exact #006338, #007861, #C4D600, #C7EEE9)
    RailOperator.adif: OperatorStyle(
      name: 'ADIF',
      primary: Color(0xFF006338), // Dark Green
      secondary: Color(0xFF007861), // Teal Green
      accent: Color(0xFFC4D600), // Lime Green
      cardBackground: Color(0x33007861),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFC7EEE9), // Mint Green
      badgeBackground: Color(0xFF006338),
      badgeText: Color(0xFFFFFFFF),
    ),

    // Iryo
    RailOperator.iryo: OperatorStyle(
      name: 'IRYO',
      primary: Color(0xFFD81E05),
      secondary: Color(0xFFD81E05),
      accent: Color(0xFFD81E05),
      cardBackground: Color(0x33D81E05),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFECC2C8),
      badgeBackground: Color(0xFFC8102E),
      badgeText: Color(0xFFFFFFFF),
    ),

    // Ouigo
    RailOperator.ouigo: OperatorStyle(
      name: 'OUIGO',
      primary: Color(0xFFE6007E),
      secondary: Color(0xFF009EE3),
      accent: Color(0xFF00C0F3),
      cardBackground: Color(0x33E6007E),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFC2E2),
      badgeBackground: Color(0xFF009EE3),
      badgeText: Color(0xFFFFFFFF),
    ),

    // Generic / Unknown Fallback
    RailOperator.unknown: OperatorStyle(
      name: 'Ferrocarril',
      primary: Color(0xFF2C3440),
      secondary: Color(0xFF1B2129),
      accent: Color(0xFF60A5FA),
      cardBackground: Color(0x332C3440),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF94A3B8),
      badgeBackground: Color(0xFF3B82F6),
      badgeText: Color(0xFFFFFFFF),
    ),
  };

  /// Returns the corresponding style or fallback for an operator.
  static OperatorStyle of(RailOperator operator) {
    return registry[operator] ?? registry[RailOperator.unknown]!;
  }

  static String normalizeRenfeService(String raw) {
    final value = raw
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const productCodes = {
      '2': 'AVE',
      '3': 'AVANT',
      '11': 'INTERCITY',
      '13': 'INTERCITY',
      '16': 'REGIONAL',
      '18': 'REGIONAL',
      '19': 'REGIONAL',
      '28': 'AVLO',
    };
    if (productCodes.containsKey(value)) return productCodes[value]!;
    if (value.contains('CERCAN') ||
        value.contains('RODALIES') ||
        value.contains('FEVE')) {
      return 'CERCANÍAS';
    }
    if (value.contains('AVLO')) return 'AVLO';
    if (value.contains('AVANT') || value == 'AVA') return 'AVANT';
    if (value.contains('INTERCITY') ||
        value.contains('INTC') ||
        value.contains('ICITY') ||
        value.contains('ALVIA') ||
        value.contains('EUROMED') ||
        value.contains('TALGO') ||
        value.contains('TRENHOTEL')) {
      return 'INTERCITY';
    }
    if (value.contains('AVE')) return 'AVE';
    if (value.contains('REGIONAL') ||
        value.contains('REG EXP') ||
        value.contains('REGIONAL EXPRES') ||
        value == 'MD' ||
        value.contains('MEDIA DISTANCIA')) {
      return 'REGIONAL';
    }
    if (value.contains('IRYO') || value == 'IRY') return 'IRYO';
    if (value.contains('OUIGO') || value == 'OUI') return 'OUIGO';
    return '';
  }

  static OperatorStyle forTrain(
    RailOperator operator,
    String trainType, {
    bool isDark = false,
  }) {
    if (operator == RailOperator.iryo) return of(RailOperator.iryo);
    if (operator == RailOperator.ouigo) return of(RailOperator.ouigo);

    final product = normalizeRenfeService(trainType);
    switch (product) {
      case 'AVE':
        return _blueStyle(isDark);
      case 'AVANT':
        return _avantStyle(isDark);
      case 'AVLO':
        return of(RailOperator.renfeAvlo);
      case 'INTERCITY':
        return _intercityStyle(isDark);
      case 'REGIONAL':
        return _regionalStyle(isDark);
      case 'CERCANÍAS':
        return of(RailOperator.renfeCercanias);
      case 'IRYO':
        return of(RailOperator.iryo);
      case 'OUIGO':
        return of(RailOperator.ouigo);
    }

    switch (operator) {
      case RailOperator.renfeAve:
        return _blueStyle(isDark);
      case RailOperator.renfeAvant:
        return _avantStyle(isDark);
      case RailOperator.renfeAvlo:
        return of(RailOperator.renfeAvlo);
      case RailOperator.renfeAlvia:
      case RailOperator.renfeIntercity:
        return _intercityStyle(isDark);
      case RailOperator.renfeMd:
      case RailOperator.renfeRegional:
        return _regionalStyle(isDark);
      case RailOperator.renfeCercanias:
        return of(RailOperator.renfeCercanias);
      default:
        return of(operator);
    }
  }

  static OperatorStyle _avantStyle(bool isDark) {
    return _blueStyle(isDark, serviceName: 'RENFE AVANT');
  }

  static OperatorStyle _blueStyle(
    bool isDark, {
    String serviceName = 'RENFE AVE',
  }) {
    final style = of(RailOperator.renfeAve);
    return OperatorStyle(
      name: serviceName,
      primary: style.primary,
      secondary: style.secondary,
      accent: isDark ? const Color(0xFF60A5FA) : style.accent,
      cardBackground: style.cardBackground,
      textPrimary: style.textPrimary,
      textSecondary: style.textSecondary,
      badgeBackground: style.badgeBackground,
      badgeText: isDark ? const Color(0xFF60A5FA) : style.badgeText,
    );
  }

  static OperatorStyle _intercityStyle(bool isDark) =>
      _purpleStyle(isDark, 'RENFE INTERCITY');

  static OperatorStyle _regionalStyle(bool isDark) =>
      _purpleStyle(isDark, 'RENFE REGIONAL');

  static OperatorStyle _purpleStyle(bool isDark, String serviceName) {
    final style = of(RailOperator.renfeIntercity);
    return OperatorStyle(
      name: serviceName,
      primary: style.primary,
      secondary: isDark ? const Color(0xFFC026D3) : style.secondary,
      accent: isDark ? const Color(0xFFE879F9) : style.accent,
      cardBackground: style.cardBackground,
      textPrimary: style.textPrimary,
      textSecondary: style.textSecondary,
      badgeBackground: style.badgeBackground,
      badgeText: isDark ? const Color(0xFFE879F9) : style.badgeText,
    );
  }

  /// Parses operator type from string identifier or pkpass passTypeIdentifier.
  static RailOperator detect(String? identifier) {
    if (identifier == null) return RailOperator.unknown;
    final lower = identifier.toLowerCase();
    if (lower.contains('avlo')) return RailOperator.renfeAvlo;
    if (lower.contains('renfe')) return RailOperator.renfe;
    if (lower.contains('adif')) return RailOperator.adif;
    if (lower.contains('iryo')) return RailOperator.iryo;
    if (lower.contains('ouigo')) return RailOperator.ouigo;
    return RailOperator.unknown;
  }
}
