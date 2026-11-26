import 'package:flutter_test/flutter_test.dart';

import 'package:anden_libre/core/theme/operator_themes.dart';

void main() {
  test('uses the commercial RENFE label and palette for each train brand', () {
    final cases = {
      'AVE': ('RENFE AVE', 0xFF0B132B, 0xFF1C3D6E),
      'AVANT': ('RENFE AVANT', 0xFF0B132B, 0xFF1C3D6E),
      'AVLO': ('RENFE AVLO', 0xFF0B132B, 0xFF00B4D8),
      'INTERCITY': ('RENFE INTERCITY', 0xFF680A51, 0xFF8E136F),
      'ALVIA': ('RENFE INTERCITY', 0xFF680A51, 0xFF8E136F),
      'EUROMED': ('RENFE INTERCITY', 0xFF680A51, 0xFF8E136F),
      'TALGO': ('RENFE INTERCITY', 0xFF680A51, 0xFF8E136F),
      'REGIONAL': ('RENFE REGIONAL', 0xFF680A51, 0xFF8E136F),
      'Regional Exprés': ('RENFE REGIONAL', 0xFF680A51, 0xFF8E136F),
      'REG.EXP.': ('RENFE REGIONAL', 0xFF680A51, 0xFF8E136F),
      'MD': ('RENFE REGIONAL', 0xFF680A51, 0xFF8E136F),
      'Media Distancia': ('RENFE REGIONAL', 0xFF680A51, 0xFF8E136F),
      'CERCANÍAS': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFC81D25),
      'Rodalies': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFC81D25),
      'FEVE': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFC81D25),
    };

    for (final entry in cases.entries) {
      final style = OperatorThemes.forTrain(RailOperator.renfe, entry.key);
      expect(style.name, entry.value.$1);
      expect(style.primary.value, entry.value.$2);
      expect(style.accent.value, entry.value.$3);
    }
  });

  test('uses the accessible AVANT highlight in dark mode only', () {
    final lightStyle = OperatorThemes.forTrain(RailOperator.renfe, 'AVANT');
    final darkStyle = OperatorThemes.forTrain(
      RailOperator.renfe,
      'AVANT',
      isDark: true,
    );

    expect(lightStyle.accent.value, 0xFF1C3D6E);
    expect(darkStyle.accent.value, 0xFF60A5FA);
    expect(darkStyle.badgeText.value, 0xFF60A5FA);
  });

  test('uses high-contrast purple highlights in dark mode', () {
    final darkStyle = OperatorThemes.forTrain(
      RailOperator.renfe,
      'INTERCITY',
      isDark: true,
    );

    expect(darkStyle.secondary.value, 0xFFC026D3);
    expect(darkStyle.accent.value, 0xFFE879F9);
    expect(darkStyle.badgeText.value, 0xFFE879F9);
  });

  test('keeps private operator labels and palettes', () {
    expect(OperatorThemes.forTrain(RailOperator.renfe, 'IRYO').name, 'IRYO');
    expect(OperatorThemes.forTrain(RailOperator.renfe, 'OUIGO').name, 'OUIGO');
  });

  test('normalizes Renfe product codes to supported service groups', () {
    expect(OperatorThemes.forTrain(RailOperator.renfe, '11').name,
        'RENFE INTERCITY');
    expect(OperatorThemes.forTrain(RailOperator.renfe, '16').name,
        'RENFE REGIONAL');
    expect(OperatorThemes.forTrain(RailOperator.renfe, '18').name,
        'RENFE REGIONAL');
  });
}
