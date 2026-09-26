import 'package:audiokiddo/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const aaText = 4.5;

  test('text on pack colours meets WCAG AA', () {
    for (final token in ['lavender', 'teal', 'sun', 'orange']) {
      expect(contrast(AkPalette.packColor(token), AkBrand.ink), greaterThanOrEqualTo(aaText), reason: token);
    }
  });

  for (final (name, p) in [('light', AkPalette.light), ('dark', AkPalette.dark)]) {
    test('$name palette meets WCAG AA', () {
      expect(contrast(p.ink, p.background), greaterThanOrEqualTo(aaText));
      expect(contrast(p.ink, p.surface), greaterThanOrEqualTo(aaText));
      expect(contrast(p.inkMuted, p.background), greaterThanOrEqualTo(aaText));
      expect(contrast(p.inkMuted, p.surface), greaterThanOrEqualTo(aaText));
      expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(aaText));
      expect(contrast(p.primary, p.background), greaterThanOrEqualTo(3), reason: 'icons and outlines');
    });
  }

  test('deep brand variants are readable on light background', () {
    for (final c in [AkBrand.lavenderDeep, AkBrand.tealDeep, AkBrand.sunDeep]) {
      expect(contrast(c, AkPalette.light.background), greaterThanOrEqualTo(aaText));
    }
  });
}
