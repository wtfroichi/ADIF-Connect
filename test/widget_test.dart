import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adif_connect/core/theme/app_theme.dart';

void main() {
  test('ADIF themes use adaptive brightness', () {
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
  });
}
