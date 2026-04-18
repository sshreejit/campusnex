import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/school_model.dart';
import '../../../core/repositories/user_repository.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../../core/widgets/app_fab.dart';

import '../providers/dashboard_providers.dart';

class AdminManagementTab extends ConsumerWidget {
  const AdminManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(schoolAdminsProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isSuperUser = currentUser?.isSuperUser ?? false;

    final school = ref.watch(currentSchoolProvider).value;
    final creatorNames =
        ref.watch(adminCreatorNamesProvider).valueOrNull ?? {};
    final userRepo = ref.read(userRepositoryProvider);

    return Container(
        color: AppColors.background,
        child: Stack(      children: [
        adminsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (admins) {
            if (admins.isEmpty) {
              return Center(
                child: Text(
                  'No admins yet. Tap + to add one.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: admins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AdminCard(
                admin: admins[i],
                currentUser: currentUser,
                isSuperUser: isSuperUser,
                school: school,
                creatorName: admins[i].createdBy != null
                    ? creatorNames[admins[i].createdBy]
                    : null,
                userRepository: userRepo,
                ref: ref,
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: AppFab(
            label: 'Add Admin',
            icon: Icons.person_add,
            onTap: () => _showAddAdminSheet(context, ref),
          ),
        ),
      ],
        ),
    );
  }

  void _showAddAdminSheet(BuildContext context, WidgetRef ref) {
    ref.invalidate(createAdminProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAdminSheet(
        onSaved: () {
          if (context.mounted) {
            Future.microtask(() {
              ref.refresh(schoolAdminsProvider);
            });
          }
        },
      ),
    );
  }

}

class _AdminCard extends StatelessWidget {
  final UserModel admin;
  final SchoolModel? school;
  final String? creatorName;
  final UserRepository userRepository;
  final WidgetRef ref;
  final UserModel? currentUser;
  final bool isSuperUser;

  const _AdminCard({
    required this.admin,
    required this.currentUser,
    required this.isSuperUser,
    required this.school,
    required this.creatorName,
    required this.userRepository,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isManager = admin.canCreateAdmin;
    final isSelf = currentUser?.id == admin.id;
    final canModify = isSuperUser || !isSelf;

    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: isManager
          ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.adminColor, width: 2),
      )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.adminColor.withAlpha(30),
            child: Text(
              admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.adminColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  admin.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isManager)
                const Tooltip(
                  message: 'Admin Manager',
                  child: Icon(Icons.star,
                      color: AppColors.adminColor, size: 18),
                ),
              const SizedBox(width: 4),
              Chip(
                label: const Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 11,
                  ),
                ),
                backgroundColor: AppColors.adminColor,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                admin.mobile,
                style: const TextStyle(color: AppColors.textSecondary),
              ),

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
            Switch(
            value: isManager,
            onChanged: isSuperUser
                ? (isManager
                ? null
                : (value) async {
              if (!value) return;

              if (school == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School not loaded yet')),
                );
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Change'),
                  content: const Text(
                      'Are you sure you want to change the Admin Manager?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('NO'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('YES'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;
              if (!context.mounted) return;

              try {
                await userRepository.setAdminManager(
                  adminId: admin.id,
                  schoolId: school!.id,
                );

                Future.microtask(() {
                  ref.invalidate(schoolAdminsProvider);
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update')),
                );
              }
            })
                : null, // 🔥 ONLY SUPER USER CAN USE SWITCH
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: canModify ? AppColors.textPrimary : Colors.grey,
                ),
                onPressed: canModify
                    ? () async {
                  final result = await _showEditAdminDialog(context);
                  if (result == null) return;

                  if (school == null ||
                      (school!.shortName ?? '').isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('School short name not set')),
                    );
                    return;
                  }

                  try {
                    await userRepository.updateUser(
                      userId: admin.id,
                      name: result.name,
                      mobile: result.mobile,
                      schoolId: school!.id,
                      schoolShortName: school!.shortName!,
                      allowModifyManager: true,
                    );

                    Future.microtask(() {
                      ref.refresh(schoolAdminsProvider);
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
                    : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: canModify ? AppColors.error : Colors.grey,
                ),
                onPressed: canModify
                    ? () => _showDeleteDialog(context)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<({String name, String mobile})?> _showEditAdminDialog(
      BuildContext context) async {
    return showDialog<({String name, String mobile})>(
      context: context,
      builder: (ctx) => _EditAdminDialog(admin: admin),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin?'),
        content: Text('Remove ${admin.name} as an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (school == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School not loaded yet')),
        );
      }
      return;
    }
    try {
      await userRepository.deleteUser(
        userId: admin.id,
        schoolId: school!.id,
      );
      if (!context.mounted) return;
      Future.microtask(() {
        ref.refresh(schoolAdminsProvider);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete admin')),
        );
      }
    }
  }
}

class _EditAdminDialog extends StatefulWidget {
  final UserModel admin;
  const _EditAdminDialog({required this.admin});

  @override
  State<_EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<_EditAdminDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  final _formKey = GlobalKey<FormState>();

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Admin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
            name: _nameCtrl.text.trim(),
            mobile: _mobileCtrl.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddAdminSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const AddAdminSheet({required this.onSaved});

  @override
  ConsumerState<AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends ConsumerState<AddAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // currentUserProvider returns null in dev mode (no Supabase auth session).
    // Fall back to the auth notifier state which holds the dev-login user.
    var currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthSuccess) currentUser = authState.user;
    }
    if (!mounted) return;
    if (currentUser == null) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Not authenticated'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final school = await ref.read(currentSchoolProvider.future);
    if (!mounted) return;
    if (school == null || (school.shortName ?? '').isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: const Text('School short name is not set. Please set it before creating a user.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await ref.read(createAdminProvider.notifier).createAdmin(
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      schoolId: currentUser.schoolId,
      schoolShortName: school.shortName!,
      createdBy: currentUser.id,
    );

    if (!mounted) return;
    final result = ref.read(createAdminProvider);
    if (result.hasError) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(result.error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      final name = _nameCtrl.text.trim();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Admin Created'),
          content: Text('$name has been added as an admin.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createAdminProvider).isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Admin',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2,color: AppColors.primary,),
              )
                  : const Text('Create Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
