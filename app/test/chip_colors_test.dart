import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color? labelColor(WidgetTester tester, String text) => tester
    .widget<RichText>(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text))
    .text
    .style
    ?.color;

void main() {
  for (final (name, brightness, palette) in [
    ('light', Brightness.light, AkPalette.light),
    ('dark', Brightness.dark, AkPalette.dark),
  ]) {
    testWidgets('$name: chip labels are visible and readable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            body: Column(
              children: [
                const Chip(label: Text('plain')),
                Builder(
                  builder: (context) => Column(
                    children: [
                      FilterChip(
                        label: const Text('off'),
                        selected: false,
                        labelStyle: selectableChipLabel(context, selected: false),
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text('on'),
                        selected: true,
                        labelStyle: selectableChipLabel(context, selected: true),
                        onSelected: (_) {},
                      ),
                      ChoiceChip(
                        label: const Text('choice'),
                        selected: true,
                        labelStyle: selectableChipLabel(context, selected: true),
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(labelColor(tester, 'plain'), palette.inkMuted);
      expect(labelColor(tester, 'off'), palette.ink);
      expect(labelColor(tester, 'on'), palette.onPrimary);
      expect(labelColor(tester, 'choice'), palette.onPrimary);
    });
  }

  testWidgets('selected navigation icon stays readable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'a'),
              NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'b'),
            ],
          ),
        ),
      ),
    );
    final icon = tester.widget<IconTheme>(
      find.ancestor(of: find.byIcon(Icons.home_rounded), matching: find.byType(IconTheme)).first,
    );
    expect(icon.data.color, AkPalette.light.ink);
  });
}
