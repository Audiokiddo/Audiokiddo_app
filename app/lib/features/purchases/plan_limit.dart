import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import 'purchase_controller.dart';
import 'shop.dart';

/// Więcej → "Zarządzaj subskrypcją": what the family has and where to change it.
class ManageSubscriptionTile extends ConsumerWidget {
  const ManageSubscriptionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final subscription = ref
        .watch(entitlementsProvider)
        .where((e) => e.scope == Scopes.allContent && e.isActiveAt(now))
        .firstOrNull;
    final subtitle = subscription == null
        ? 'Wybierz abonament: miesięcznie albo rocznie'
        : 'Abonament dla całej rodziny. Zmień okres albo zarządzaj płatnością';
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
                  title: Text(subscription == null ? 'Wybierz abonament' : 'Zmień okres'),
                  subtitle: const Text('Płatność raz w roku jest tańsza'),
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
