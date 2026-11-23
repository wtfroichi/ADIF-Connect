import 'package:flutter/material.dart';

/// Supported rail operators.
enum RailOperator {
  renfe,
  renfeAvlo,
  renfeAve,
  renfeAvant,
  renfeIntercity,
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
      badgeBackground: Color(0xFF00B4D8),
      badgeText: Color(0xFF0B132B),
    ),
    RailOperator.renfeAve: OperatorStyle(
      name: 'RENFE AVE',
      primary: Color(0xFF0B132B),
      secondary: Color(0xFF1C3D6E),
      accent: Color(0xFF1C3D6E),
      cardBackground: Color(0x330B132B),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD8E2F0),
      badgeBackground: Color(0xFF1C3D6E),
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
      badgeBackground: Color(0xFF1C3D6E),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeIntercity: OperatorStyle(
      name: 'RENFE INTERCITY',
      primary: Color(0xFF1B365D),
      secondary: Color(0xFF2B5B84),
      accent: Color(0xFF2B5B84),
      cardBackground: Color(0x331B365D),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD5E3F0),
      badgeBackground: Color(0xFF2B5B84),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeCercanias: OperatorStyle(
      name: 'RENFE CERCANÍAS',
      primary: Color(0xFFEF3340),
      secondary: Color(0xFF0B132B),
      accent: Color(0xFFEF3340),
      cardBackground: Color(0x33EF3340),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFD8DB),
      badgeBackground: Color(0xFFEF3340),
      badgeText: Color(0xFFFFFFFF),
    ),
    RailOperator.renfeRegional: OperatorStyle(
      name: 'RENFE REGIONAL',
      primary: Color(0xFF1B365D),
      secondary: Color(0xFF2B5B84),
      accent: Color(0xFF2B5B84),
      cardBackground: Color(0x331B365D),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD5E3F0),
      badgeBackground: Color(0xFF2B5B84),
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
      primary: Color(0xFFC8102E),
      secondary: Color(0xFF8B0018),
      accent: Color(0xFFFF4D6A),
      cardBackground: Color(0x33C8102E),
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

  static OperatorStyle forTrain(RailOperator operator, String trainType) {
    if (operator != RailOperator.renfe && operator != RailOperator.renfeAvlo) {
      return of(operator);
    }

    final product = trainType.toUpperCase();
    if (product.contains('AVLO')) return of(RailOperator.renfeAvlo);
    if (product.contains('AVANT')) return of(RailOperator.renfeAvant);
    if (product.contains('INTERCITY') || product.contains('INTC')) {
      return of(RailOperator.renfeIntercity);
    }
    if (product.contains('CERCAN')) return of(RailOperator.renfeCercanias);
    if (product.contains('REGIONAL') ||
        product == 'MD' ||
        product.contains('REG.EXP')) {
      return of(RailOperator.renfeRegional);
    }
    if (product.contains('AVE')) return of(RailOperator.renfeAve);
    if (operator == RailOperator.renfeAvlo) return of(RailOperator.renfeAvlo);
    return of(RailOperator.renfe);
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
