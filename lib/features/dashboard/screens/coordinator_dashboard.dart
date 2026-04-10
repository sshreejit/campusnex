import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

class CoordinatorDashboard extends ConsumerWidget {
  const CoordinatorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = switch (ref.watch(authNotifierProvider)) {
      AuthSuccess(:final user) => user.name,
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinator Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleBanner(
            label: 'Coordinator',
            color: AppColors.coordinatorColor,
            userName: userName,
          ),
          const Expanded(child: _PlaceholderContent('Coordinator')),
        ],
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  final String label;
  final Color color;
  final String userName;

  const _RoleBanner({
    required this.label,
    required this.color,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withAlpha(25),
      child: Row(
        children: [
          Chip(
            label: Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          if (userName.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              'Welcome, $userName',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  final String role;
  const _PlaceholderContent(this.role);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$role features coming soon',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
