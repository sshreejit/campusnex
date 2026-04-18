import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import 'administrators_tab.dart';
import 'designation_tab.dart';
import 'roles_tab.dart';
import '../../../classes/presentation/classes_tab.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,

      child: Column(
        children: [
          Container(
            color: AppColors.charcoalSteel,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'Administrators'),
                Tab(text: 'Designations'),
                Tab(text: 'Roles'),
                Tab(text: 'Classes'),
              ],
            ),
          ),

          const Expanded(
            child: TabBarView(
              children: [
                AdministratorsTab(),
                DesignationTab(),
                RolesTab(),
                ClassesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}