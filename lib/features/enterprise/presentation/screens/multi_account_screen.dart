import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../shared/widgets/omega_avatar.dart';

class MultiAccountScreen extends ConsumerWidget {
  const MultiAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteConstants.accountSetup);
            },
            tooltip: 'Add account',
          ),
        ],
      ),
      body: FutureBuilder<List<int>>(
        future: ref.read(deltaRpcClientProvider).getAllAccountIds(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final ids = snap.data!;
          if (ids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 64, color: OmegaColors.textDisabled),
                  const SizedBox(height: 16),
                  Text('No accounts', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: ids.length + 1,
            itemBuilder: (ctx, i) {
              if (i == ids.length) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: OmegaColors.inputFill,
                    child: Icon(Icons.add_rounded, color: OmegaColors.primary),
                  ),
                  title: const Text('Add Account'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteConstants.accountSetup);
                  },
                );
              }
              return _AccountTile(accountId: ids[i]);
            },
          );
        },
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  final int accountId;

  const _AccountTile({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(deltaRpcClientProvider).getAccountInfo(accountId),
      builder: (ctx, snap) {
        final info = snap.data;
        final email = info?['addr'] as String? ?? 'Loading...';
        final name = info?['display_name'] as String? ?? email;
        final isActive = accountId == 1; // TODO: track selected account

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              OmegaAvatar(name: name, size: 48),
              if (isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: OmegaColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(name, style: OmegaTextStyles.titleSmall),
          subtitle: Text(email, style: OmegaTextStyles.bodySmall),
          trailing: isActive
              ? const Text('Active', style: TextStyle(color: OmegaColors.primary, fontSize: 12, fontWeight: FontWeight.w600))
              : null,
          onTap: () async {
            await ref.read(deltaRpcClientProvider).selectAccount(accountId);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        );
      },
    );
  }
}
