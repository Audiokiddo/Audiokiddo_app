import 'package:audiokiddo_studio/crm/crm_screen.dart';
import 'package:audiokiddo_studio/crm/crm_widgets.dart';
import 'package:audiokiddo_studio/server/studio_server.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the CRM asks an admin to sign in first', (tester) async {
    final server = StudioServer(
      SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studioServerProvider.overrideWithValue(server)],
        child: const MaterialApp(home: Scaffold(body: CrmScreen())),
      ),
    );
    expect(find.text('CRM AudioKiddo'), findsOneWidget);
    expect(find.text('Wyślij kod'), findsOneWidget);
  });

  test('only decided or own items reach the boards', () {
    final list = decided([
      {'title': 'a', 'decision': null},
      {'title': 'b', 'decision': 'approved'},
      {'title': 'c', 'decision': 'pending'},
      {'title': 'd', 'decision': 'rejected'},
    ]);
    expect([for (final i in list) i['title']], ['a', 'b']);
  });

  testWidgets('a card shows type, owner, due date and folded text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrmCard(
            item: {
              'title': 'Pakiet Kosmos',
              'area': 'pack',
              'owner': 'Nela',
              'due': '2026-11-01',
              'source': 'ai',
              'priority': 1,
              'body': 'x' * 400,
            },
          ),
        ),
      ),
    );
    expect(find.text('Pakiet'), findsOneWidget);
    expect(find.textContaining('Nela · termin 2026-11-01 · od agenta'), findsOneWidget);
    expect(find.textContaining('…'), findsOneWidget);
  });
}
