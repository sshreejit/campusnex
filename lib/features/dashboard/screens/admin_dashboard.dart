import '../../staff/screens/staff_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/text_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/repositories/student_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
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
      const Tab(icon: Icon(Icons.badge), text: 'Staff'),
      const Tab(icon: Icon(Icons.school), text: 'Students'),
      if (canManageAdmins)
        const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
    ];

    final tabViews = [
      const StaffScreen(),
      const _StudentManagementTab(),
      if (canManageAdmins) const _AdminManagementTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
          bottom: TabBar(tabs: tabs),
        ),
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoleBanner(
              label: 'Admin',
              color: AppColors.adminColor,
              userName: userName,
            ),
            Expanded(
              child: TabBarView(children: tabViews),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin Management Tab ──────────────────────────────────────────────────────

class _AdminManagementTab extends ConsumerWidget {
  const _AdminManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(schoolAdminsProvider);
    final creatorNames =
        ref.watch(adminCreatorNamesProvider).valueOrNull ?? {};
    final rolesAsync = ref.watch(rolesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Admins Section ──
        _SectionHeader(
          title: 'Admins',
          onAdd: () => _showAddAdminSheet(context, ref),
        ),
        const SizedBox(height: 8),
        adminsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (admins) {
            if (admins.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No admins yet.')),
              );
            }
            return Column(
              children: admins
                  .map((admin) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AdminCard(
                          admin: admin,
                          creatorName: admin.createdBy != null
                              ? creatorNames[admin.createdBy]
                              : null,
                          onEdit: () =>
                              _showEditAdminSheet(context, ref, admin),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        // ── Roles Section ──
        _SectionHeader(
          title: 'Roles',
          onAdd: () => _showAddRoleSheet(context, ref),
        ),
        const SizedBox(height: 8),
        rolesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (roles) {
            if (roles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No roles yet.')),
              );
            }
            return Column(
              children: roles
                  .map((role) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RoleCard(
                          role: role,
                          onDelete: () => _deleteRole(context, ref, role),
                          onEdit: () => _showEditRoleSheet(context, ref, role),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddAdminSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddAdminSheet(),
    );

    if (result == true) {
      ref.invalidate(schoolAdminsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin added successfully')),
        );
      }
    }
  }

  Future<void> _showEditAdminSheet(
      BuildContext context, WidgetRef ref, UserModel admin) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditAdminSheet(admin: admin),
    );

    if (result == true) {
      ref.invalidate(schoolAdminsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin updated successfully')),
        );
      }
    }
  }

  Future<void> _showAddRoleSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddRoleSheet(),
    );

    if (result == true) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role added successfully')),
        );
      }
    }
  }

  Future<void> _showEditRoleSheet(
      BuildContext context, WidgetRef ref, RoleModel role) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddRoleSheet(role: role),
    );

    if (result == true) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteRole(
      BuildContext context, WidgetRef ref, RoleModel role) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    final result = await ref.read(rolesRepositoryProvider).deleteRole(
          roleId: role.id,
          schoolId: currentUser.schoolId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result.error?.replaceFirst('Exception: ', '') ??
                      'Delete failed')),
        );
      }
    }
  }
}

class _AdminCard extends StatelessWidget {
  final UserModel admin;
  final String? creatorName;
  final VoidCallback onEdit;

  const _AdminCard({
    required this.admin,
    required this.onEdit,
    this.creatorName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.adminColor.withAlpha(30),
          child: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.adminColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(admin.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(admin.mobile),
            if (creatorName != null)
              Text(
                'Created by: $creatorName',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (admin.canCreateAdmin)
              const Chip(
                label: Text('Manager',
                    style: TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: AppColors.adminColor,
                padding: EdgeInsets.zero,
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAdminSheet extends ConsumerStatefulWidget {
  const _AddAdminSheet();

  @override
  ConsumerState<_AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends ConsumerState<_AddAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      final school = await ref.read(currentSchoolProvider.future);
      if (school == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      await ref.read(createAdminProvider.notifier).createAdmin(
            name: _nameCtrl.text.trim(),
            mobile: _mobileCtrl.text.trim(),
            schoolId: currentUser.schoolId,
            schoolShortName: school.shortName ?? school.name,
            createdBy: currentUser.id,
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Admin',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Admin'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAdminSheet extends ConsumerStatefulWidget {
  final UserModel admin;
  const _EditAdminSheet({required this.admin});

  @override
  ConsumerState<_EditAdminSheet> createState() => _EditAdminSheetState();
}

class _EditAdminSheetState extends ConsumerState<_EditAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.admin.name);
    _mobileCtrl = TextEditingController(text: widget.admin.mobile);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final school = await ref.read(currentSchoolProvider.future);
      if (school == null || (school.shortName ?? '').isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('School short name not set')),
          );
        }
        return;
      }

      await ref.read(userRepositoryProvider).updateUser(
            userId: widget.admin.id,
            name: _nameCtrl.text.trim(),
            mobile: _mobileCtrl.text.trim(),
            schoolId: school.id,
            schoolShortName: school.shortName!,
            allowModifyManager: true,
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Admin',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RoleCard({
    required this.role,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = toCamelCase(role.name);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.adminColor.withAlpha(30),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.adminColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(displayName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit role',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete role',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Role Sheet ────────────────────────────────────────────────────────────

class _AddRoleSheet extends ConsumerStatefulWidget {
  final RoleModel? role;

  const _AddRoleSheet({this.role});

  @override
  ConsumerState<_AddRoleSheet> createState() => _AddRoleSheetState();
}

class _AddRoleSheetState extends ConsumerState<_AddRoleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  bool get _isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      final inputName = _nameCtrl.text.trim().toLowerCase();
      final existingRoles = ref.read(rolesProvider).valueOrNull ?? [];
      final isDuplicate = existingRoles.any((r) =>
          r.name.trim().toLowerCase() == inputName &&
          r.id != widget.role?.id);
      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role already exists')),
          );
        }
        return;
      }

      final RoleResult result;
      if (_isEditing) {
        result = await ref.read(rolesRepositoryProvider).updateRole(
              roleId: widget.role!.id,
              schoolId: currentUser.schoolId,
              name: _nameCtrl.text.trim(),
            );
      } else {
        result = await ref.read(rolesRepositoryProvider).addRole(
              name: _nameCtrl.text.trim(),
              schoolId: currentUser.schoolId,
              createdBy: currentUser.id,
            );
      }

      if (result.success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result.error?.replaceFirst('Exception: ', '') ??
                        (_isEditing ? 'Failed to update role' : 'Failed to add role'))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Role' : 'Add Role',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save' : 'Add Role'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Student Management Tab ────────────────────────────────────────────────────

class _StudentManagementTab extends ConsumerWidget {
  const _StudentManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(schoolStudentsProvider);

    return Stack(
      children: [
        studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (students) {
            if (students.isEmpty) {
              return const Center(
                  child: Text('No students yet. Tap + to add.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _StudentCard(student: students[i]),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_add_student',
            onPressed: () => _showAddStudentSheet(context, ref),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Student'),
          ),
        ),
      ],
    );
  }

  void _showAddStudentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddStudentSheet(
        onSaved: () => ref.invalidate(schoolStudentsProvider),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final name = (student['name'] as String?) ?? '-';
    final classId =
        (student['class_id'] as String?) ?? 'Unassigned';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.coordinatorColor.withAlpha(30),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.coordinatorColor,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name),
        subtitle: Text('Class: $classId'),
      ),
    );
  }
}

class _AddStudentSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddStudentSheet({required this.onSaved});

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final UserModel? currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      await ref.read(studentRepositoryProvider).addStudent(
            schoolId: currentUser.schoolId,
            name: _nameCtrl.text.trim(),
          );

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Student',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Class, section and parent can be assigned after creation.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

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
