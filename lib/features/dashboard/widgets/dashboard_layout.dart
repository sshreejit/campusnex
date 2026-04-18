import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

import '../config/dashboard_config.dart';
import '../utils/role_resolver.dart';
import 'school_header.dart';

class DashboardLayout extends ConsumerWidget {
  const DashboardLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    final user = authState is AuthSuccess ? authState.user : null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// 🧠 Resolve Role
    final role = getUserRole(user);

    /// 🧠 Get Config
    final config = getDashboardConfig(
      role: role,
      userName: user.name,
      canCreateAdmin: user.canCreateAdmin,
    );

    return DefaultTabController(
      length: config.tabs.length,

      child: Container(
        color: AppColors.maroon,

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(2),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: Container(
                color: AppColors.charcoalSteel,

                child: Scaffold(
                  backgroundColor: Colors.transparent,

                  body: Column(
                    children: [
                      /// ───── HEADER ─────
                      const SchoolHeader(),

                      /// ───── TAB BAR ─────
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent, // 🔥 removes default bottom line gap
                        ),
                        child: TabBar(
                          padding: EdgeInsets.zero, // no outer padding
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          indicatorPadding: EdgeInsets.zero,
                          tabs: config.tabs,
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                        ),
                      ),

                      /// ───── CONTENT ─────
                      Expanded(
                        child: TabBarView(
                          children: config.views,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}