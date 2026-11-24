import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/core/theme/operator_themes.dart';

void main() {
  test('uses the commercial RENFE label and palette for each train brand', () {
    final cases = {
      'AVE': ('RENFE AVE', 0xFF0B132B, 0xFF1C3D6E),
      'AVANT': ('RENFE AVANT', 0xFF0B132B, 0xFF1C3D6E),
      'AVLO': ('RENFE AVLO', 0xFF0B132B, 0xFF00B4D8),
      'INTERCITY': ('RENFE INTERCITY', 0xFF680A51, 0xFFC026D3),
      'ALVIA': ('RENFE INTERCITY', 0xFF680A51, 0xFFC026D3),
      'EUROMED': ('RENFE INTERCITY', 0xFF680A51, 0xFFC026D3),
      'TALGO': ('RENFE INTERCITY', 0xFF680A51, 0xFFC026D3),
      'REGIONAL': ('RENFE REGIONAL', 0xFF680A51, 0xFFC026D3),
      'Regional Exprés': ('RENFE REGIONAL', 0xFF680A51, 0xFFC026D3),
      'REG.EXP.': ('RENFE REGIONAL', 0xFF680A51, 0xFFC026D3),
      'MD': ('RENFE REGIONAL', 0xFF680A51, 0xFFC026D3),
      'Media Distancia': ('RENFE REGIONAL', 0xFF680A51, 0xFFC026D3),
      'CERCANÍAS': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFEF3340),
      'Rodalies': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFEF3340),
      'FEVE': ('RENFE CERCANÍAS', 0xFFEF3340, 0xFFEF3340),
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
