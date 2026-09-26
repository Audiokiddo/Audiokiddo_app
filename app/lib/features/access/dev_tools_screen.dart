import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'access_controller.dart';

final _devModeProvider = FutureProvider<DevAccessMode>((ref) async {
  final backend = ref.watch(entitlementBackendProvider);
  return backend is DevEntitlementBackend ? backend.mode() : DevAccessMode.none;
});

/// Debug builds only: simulate purchases and the offline lease until Etap 3.
class DevToolsScreen extends ConsumerWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(_devModeProvider).value;
    final access = ref.watch(accessProvider).value;
    final backend = ref.watch(entitlementBackendProvider);
    final lease = access?.leaseValidUntil;

    Future<void> setMode(DevAccessMode m) async {
      if (backend is! DevEntitlementBackend) return;
      await backend.setMode(m);
      ref.invalidate(_devModeProvider);
      await ref.read(accessProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devTools)),
      body: ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          Text(l10n.devToolsHint),
          const SizedBox(height: AkSpace.l),
          Text(l10n.devAccessMode, style: Theme.of(context).textTheme.titleMedium),
          RadioGroup<DevAccessMode>(
            groupValue: mode,
            onChanged: (m) => m == null ? null : setMode(m),
            child: Column(
              children: [
                for (final m in DevAccessMode.values)
                  RadioListTile<DevAccessMode>(value: m, title: Text(m.label)),
              ],
            ),
          ),
          const SizedBox(height: AkSpace.m),
          Text(
            lease == null
                ? l10n.devLeaseNone
                : l10n.devLeaseUntil(lease.toLocal().toString().substring(0, 16)),
          ),
          const SizedBox(height: AkSpace.m),
          OutlinedButton(
            onPressed: () => ref.read(accessProvider.notifier).expireLeaseForTesting(),
            child: Text(l10n.devExpireLease),
          ),
          const SizedBox(height: AkSpace.s),
          FilledButton(
            onPressed: () => ref.read(accessProvider.notifier).refresh(),
            child: Text(l10n.devRefresh),
          ),
        ],
      ),
    );
  }
}
