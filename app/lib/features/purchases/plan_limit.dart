import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../family/family.dart';
import 'purchase_controller.dart';
import 'shop.dart';

/// Whether one more child profile fits the subscription. When it does not, a short sheet says
/// how many children the plan covers and leads to the plans (moving up is the store's upgrade).
/// Without a subscription there is no limit: the free plays and bought packs are for everyone.
Future<bool> mayAddChild(BuildContext context, WidgetRef ref) async {
  final seats = ref.read(childSeatsProvider);
  final children = ref.read(familyProvider).value?.children.length ?? 0;
  if (seats == null || children < seats) return true;
  final upgrade = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SzopSticker(SzopPose.zdziwiony, height: 88)),
              const SizedBox(height: 8),
              Text(
                'Twój abonament obejmuje ${seats == 1 ? '1 dziecko' : '$seats dzieci'}',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Drugie dziecko to +5 zł miesięcznie, cała rodzina (do 5 dzieci) +10 zł. '
                'Sklep przeliczy to, co już zapłaciłeś.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Zobacz plany'),
              ),
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nie teraz')),
            ],
          ),
        ),
      );
    },
  );
  if (upgrade == true && context.mounted) await context.push('/abonament');
  return false;
}

/// Więcej → "Zarządzaj subskrypcją": what the family has and where to change it.
class ManageSubscriptionTile extends ConsumerWidget {
  const ManageSubscriptionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(childSeatsProvider);
    final now = ref.watch(clockProvider)();
    final subscription = ref
        .watch(entitlementsProvider)
        .where((e) => e.scope == Scopes.allContent && e.isActiveAt(now))
        .firstOrNull;
    final subtitle = switch (seats) {
      null => 'Wybierz plan: 1, 2 lub 3–5 dzieci, miesięcznie albo rocznie',
      99 => 'Abonament dla całej rodziny',
      1 => 'Twój plan: 1 dziecko. Zmień na większy albo roczny',
      final n => 'Twój plan: $n dzieci. Zmień albo zarządzaj płatnością',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.workspace_premium_rounded, color: AkBrand.tealDeep),
      title: const Text('Zarządzaj subskrypcją'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useRootNavigator: true,
        builder: (sheet) {
          final store = switch (subscription?.source) {
            EntitlementSource.woocommerce => (
              'Płatność i rezygnacja na audiokiddo.pl',
              'Abonament kupiony w sklepie internetowym',
              Uri.parse('https://audiokiddo.pl/moje-konto/'),
            ),
            EntitlementSource.manual => null,
            _ => (
              Platform.isIOS ? 'Płatność i rezygnacja w App Store' : 'Płatność i rezygnacja w Google Play',
              'Tam zmienisz kartę, okres albo anulujesz',
              manageSubscriptionsUrl,
            ),
          };
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.upgrade_rounded),
                  title: Text(seats == null ? 'Wybierz abonament' : 'Zmień plan'),
                  subtitle: const Text('Więcej dzieci albo płatność raz w roku (taniej)'),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('/abonament');
                  },
                ),
                if (store case (final title, final hint, final url))
                  ListTile(
                    leading: const Icon(Icons.open_in_new_rounded),
                    title: Text(title),
                    subtitle: Text(hint),
                    onTap: () {
                      Navigator.pop(sheet);
                      openWithGate(context, url);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('Przywróć zakupy'),
                  subtitle: const Text('Po zmianie telefonu albo ponownej instalacji'),
                  onTap: () {
                    Navigator.pop(sheet);
                    ref.read(purchaseControllerProvider.notifier).restore();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
