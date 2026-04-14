import 'package:campusnex/core/models/class_model.dart';
import '../../classes/providers/class_provider.dart';
import '../../classes/repositories/class_repository.dart';
import '../../staff/screens/staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/text_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/repositories/student_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../designations/models/designation_model.dart';
import '../../designations/providers/designation_provider.dart';
import '../../designations/repositories/designation_repository.dart';
import '../../roles/models/role_model.dart';
import '../../roles/repositories/roles_repository.dart';
import '../providers/dashboard_providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final userName = currentUser?.name ?? '';
    final canManageAdmins = currentUser?.canCreateAdmin ?? false;

    final tabs = [
      const Tab(text: 'Staff'),
      const Tab(text: 'Students'),
      if (canManageAdmins) const Tab(text: 'Management'),
    ];

    final tabViews = [
      const StaffScreen(),
      _StudentManagementTab(), // Removed const
      if (canManageAdmins) const _AdminManagementTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Container(
        color: AppColors.charcoalSteel,
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.charcoalSteel,
              elevation: 0,
              titleSpacing: 12,
              automaticallyImplyLeading: false,
              toolbarHeight: 50,
              title: Row(
                children: [
                  _buildAdminBadge(canManageAdmins),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome, $userName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                _buildActionMenu(ref),
              ],
              bottom: TabBar(
                tabs: tabs,
                isScrollable: false,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            body: TabBarView(children: tabViews),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBadge(bool isManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isManager) ...[
            const Icon(Icons.star, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
          ],
          const Text(
            'ADMIN',
            style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) => value == 'logout' ? ref.read(authNotifierProvider.notifier).signOut() : null,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [Icon(Icons.logout, size: 18, color: AppColors.error), SizedBox(width: 12), Text('Logout')]),
        ),
      ],
    );
  }
}

// ── Admin Management Tab ──────────────────────────────────────────────────────

class _AdminManagementTab extends ConsumerWidget {
  const _AdminManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(schoolAdminsProvider);
    final creatorNames = ref.watch(adminCreatorNamesProvider).valueOrNull ?? {};
    final rolesAsync = ref.watch(rolesProvider);
    final designationsAsync = ref.watch(designationsProvider);
    final classesAsync = ref.watch(classesProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isManager = currentUser?.canCreateAdmin ?? false;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionHeader(title: 'ADMINISTRATORS', onAdd: () => _showAddAdminSheet(context, ref)),
        adminsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (admins) => Column(
            children: admins.map((admin) => _AdminCard(
              admin: admin,
              creatorName: creatorNames[admin.createdBy],
              onEdit: () => _showEditAdminSheet(context, ref, admin),
              onDelete: isManager && admin.id != currentUser?.id ? () => _deleteAdmin(context, ref, admin) : null,
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'ROLES', onAdd: () => _showAddRoleSheet(context, ref)),
        rolesAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => Text('Error: $e'),
          data: (roles) => Column(
            children: roles.map((role) => _RoleCard(
              role: role,
              onDelete: () => _deleteRole(context, ref, role),
              onEdit: () => _showEditRoleSheet(context, ref, role),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'DESIGNATIONS', onAdd: () => _showAddDesignationSheet(context, ref)),
        designationsAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => Text('Error: $e'),
          data: (designations) => Column(
            children: designations.map((d) => _DesignationCard(
              designation: d,
              onDelete: () => _deleteDesignation(context, ref, d),
              onEdit: () => _showEditDesignationSheet(context, ref, d),
            )).toList(),
          ),
        ),

        const SizedBox(height: 20),
        _SectionHeader(
          title: 'CLASSES',
          onAdd: () => _showClassSheet(context, ref),
        ),
        classesAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => Text('Error: $e'),
          data: (classes) => Column(
            children: classes.map((c) {
              return Card(
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${c.className} - ${c.section}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showClassSheet(
                          context,
                          ref,
                          classModel: c,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                        onPressed: () => _deleteClass(context, ref, c),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper Scopes
  void _showAddAdminSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _AddAdminSheet(), // Removed const
  ).then((val) => val == true ? ref.invalidate(schoolAdminsProvider) : null);

  void _showEditAdminSheet(BuildContext context, WidgetRef ref, UserModel admin) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _EditAdminSheet(admin: admin),
  ).then((val) => val == true ? ref.invalidate(schoolAdminsProvider) : null);

  void _showAddRoleSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _AddRoleSheet(), // Removed const
  ).then((val) => val == true ? ref.invalidate(rolesProvider) : null);

  void _showEditRoleSheet(BuildContext context, WidgetRef ref, RoleModel role) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _AddRoleSheet(role: role),
  ).then((val) => val == true ? ref.invalidate(rolesProvider) : null);

  void _showAddDesignationSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _AddDesignationSheet(), // Removed const
  ).then((val) => val == true ? ref.invalidate(designationsProvider) : null);

  void _showEditDesignationSheet(BuildContext context, WidgetRef ref, DesignationModel d) => showModalBottomSheet(
    context: context, isScrollControlled: true, builder: (_) => _AddDesignationSheet(designation: d),
  ).then((val) => val == true ? ref.invalidate(designationsProvider) : null);

  void _showClassSheet(BuildContext context, WidgetRef ref, {ClassModel? classModel,}) =>
      showModalBottomSheet(context: context, isScrollControlled: true,builder: (_) => _ClassSheet(classModel: classModel),
      ).then((val) => val == true ? ref.invalidate(classesProvider) : null);

  // CRUD Logic
  Future<void> _deleteAdmin(
      BuildContext context,
      WidgetRef ref,
      UserModel admin,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text(
          'Are you sure you want to delete "${admin.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    await ref.read(userRepositoryProvider).deleteUser(
      userId: admin.id,
      schoolId: user.schoolId,
    );

    ref.invalidate(schoolAdminsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin deleted')),
      );
    }
  }

  Future<void> _deleteRole(
      BuildContext context,
      WidgetRef ref,
      RoleModel role,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text(
          'Are you sure you want to delete "${role.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final result = await ref.read(rolesRepositoryProvider).deleteRole(
      roleId: role.id,
      schoolId: user.schoolId,
    );

    if (result.success) {
      ref.invalidate(rolesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role deleted')),
        );
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(result.error ?? 'Failed to delete role'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteDesignation(
      BuildContext context,
      WidgetRef ref,
      DesignationModel d,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Designation'),
        content: Text(
          'Are you sure you want to delete "${d.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(designationRepositoryProvider)
        .deleteDesignation(id: d.id);

    if (result.success) {
      ref.invalidate(designationsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Designation deleted')),
        );
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(result.error ?? 'Delete failed'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteClass(
      BuildContext context,
      WidgetRef ref,
      ClassModel c,
      ) async {
    final result =
    await ref.read(classRepositoryProvider).deleteClass(c.id);

    if (result.success) {
      ref.invalidate(classesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted')),
        );
      }
    }
  }
}

// ── Components & Sheets (Unified) ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
      TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 14), label: const Text('ADD', style: TextStyle(fontSize: 11))),
    ]);
  }
}

class _AdminCard extends StatelessWidget {
  final UserModel admin;
  final String? creatorName;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  const _AdminCard({required this.admin, required this.onEdit, this.creatorName, this.onDelete});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    dense: true, visualDensity: VisualDensity.compact,
    title: Text(admin.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    subtitle: Text(admin.mobile, style: const TextStyle(fontSize: 11)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
      if (onDelete != null) IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: onDelete),
    ]),
  ));
}

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _RoleCard({required this.role, required this.onDelete, required this.onEdit});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    dense: true, title: Text(toCamelCase(role.name), style: const TextStyle(fontSize: 13)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
      IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: onDelete),
    ]),
  ));
}

class _DesignationCard extends StatelessWidget {
  final DesignationModel designation;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _DesignationCard({required this.designation, required this.onDelete, required this.onEdit});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    dense: true, title: Text(toCamelCase(designation.name), style: const TextStyle(fontSize: 13)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
      IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: onDelete),
    ]),
  ));
}

// ── Management Sheets (Add/Edit) ───────────────────────────────────────────────

class _AddAdminSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddAdminSheet> createState() => _AddAdminSheetState();
}
class _AddAdminSheetState extends ConsumerState<_AddAdminSheet> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
      TextFormField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add Admin'))
    ]),
  );
}

class _EditAdminSheet extends ConsumerStatefulWidget {
  final UserModel admin;

  const _EditAdminSheet({required this.admin});

  @override
  ConsumerState<_EditAdminSheet> createState() => _EditAdminSheetState();
}

class _EditAdminSheetState extends ConsumerState<_EditAdminSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.admin.name);
    _mobileCtrl = TextEditingController(text: widget.admin.mobile);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Admin',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: _mobileCtrl,
            decoration: const InputDecoration(labelText: 'Mobile'),
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _updateAdmin,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Update Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAdmin() async {
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    if (name.isEmpty || mobile.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Error'),
          content: Text('All fields required'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not found');

      final shortName = user.schoolShortName ?? '';

      await ref.read(userRepositoryProvider).updateUser(
        userId: widget.admin.id,
        schoolId: user.schoolId,
        name: name,
        mobile: mobile,
        schoolShortName: shortName,
      );

      ref.invalidate(schoolAdminsProvider);

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin updated')),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _AddRoleSheet extends ConsumerStatefulWidget {
  final RoleModel? role;

  const _AddRoleSheet({this.role});

  @override
  ConsumerState<_AddRoleSheet> createState() => _AddRoleSheetState();
}

class _AddRoleSheetState extends ConsumerState<_AddRoleSheet> {
  late TextEditingController _nameCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.role == null ? 'Add Role' : 'Edit Role',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Role Name'),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _saveRole,
            child: _loading
                ? const CircularProgressIndicator()
                : Text(widget.role == null ? 'Add Role' : 'Update Role'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRole() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final repo = ref.read(rolesRepositoryProvider);

    final result = widget.role == null
        ? await repo.addRole(
      name: name,
      schoolId: user.schoolId,
      createdBy: user.id,
    )
        : await repo.updateRole(
      roleId: widget.role!.id,
      schoolId: user.schoolId,
      name: name,
    );

    setState(() => _loading = false);

    if (result.success) {
      ref.invalidate(rolesProvider);
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.role == null ? 'Role added' : 'Role updated')),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(result.error ?? 'Operation failed'),
        ),
      );
    }
  }
}

class _AddDesignationSheet extends ConsumerStatefulWidget {
  final DesignationModel? designation;

  const _AddDesignationSheet({this.designation});

  @override
  ConsumerState<_AddDesignationSheet> createState() => _AddDesignationSheetState();
}

class _AddDesignationSheetState extends ConsumerState<_AddDesignationSheet> {
  late TextEditingController _nameCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.designation?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.designation == null ? 'Add Designation' : 'Edit Designation',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Designation'),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _saveDesignation,
            child: _loading
                ? const CircularProgressIndicator()
                : Text(widget.designation == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDesignation() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    final repo = ref.read(designationRepositoryProvider);

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final result = widget.designation == null
        ? await repo.addDesignation(
      name: name,
      schoolId: user.schoolId, // ✅ FIX
    )
        : await repo.updateDesignation(
      id: widget.designation!.id,
      name: name,
    );

    setState(() => _loading = false);

    if (result.success) {
      ref.invalidate(designationsProvider);
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.designation == null ? 'Added' : 'Updated')),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(result.error ?? 'Operation failed'),
        ),
      );
    }
  }
}

class _ClassSheet extends ConsumerStatefulWidget {
  final ClassModel? classModel;

  const _ClassSheet({this.classModel});

  @override
  ConsumerState<_ClassSheet> createState() => _ClassSheetState();
}

class _ClassSheetState extends ConsumerState<_ClassSheet> {
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _classCtrl.text = widget.classModel!.className;
      _sectionCtrl.text = widget.classModel!.section;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isEdit ? 'Edit Class' : 'Add Class',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _classCtrl,
            decoration: const InputDecoration(
              labelText: 'Class (e.g., 1, Nursery)',
            ),
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: _sectionCtrl,
            decoration: const InputDecoration(
              labelText: 'Section (e.g., A, Rose)',
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_classCtrl.text.trim().isEmpty ||
        _sectionCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Both fields required');
      return;
    }

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() => _loading = true);

    final repo = ref.read(classRepositoryProvider);

    final result = _isEdit
        ? await repo.updateClass(
      id: widget.classModel!.id,
      className: _classCtrl.text,
      section: _sectionCtrl.text,
    )
        : await repo.addClass(
      className: _classCtrl.text,
      section: _sectionCtrl.text,
      schoolId: user.schoolId,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }
}

// ── Student Management ────────────────────────────────────────────────────────

class _StudentManagementTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Student List'));
}