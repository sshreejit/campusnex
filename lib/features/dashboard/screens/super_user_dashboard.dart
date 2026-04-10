import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/school_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/school_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../providers/dashboard_providers.dart';

class SuperUserDashboard extends ConsumerWidget {
  const SuperUserDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = switch (ref.watch(authNotifierProvider)) {
      AuthSuccess(:final user) => user.name,
      _ => '',
    };

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Super User Dashboard'),
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school_outlined), text: 'School'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Overview'),
            ],
          ),
        ),
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoleBanner(
                label: 'Super User',
                color: AppColors.superUserColor,
                userName: userName,
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _SchoolProfileTab(),
                    _AdminManagementTab(),
                    _SchoolOverviewTab(),
                  ],
                ),
              ),
            ],
          ),
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
    final school = ref.watch(currentSchoolProvider).value;
    final creatorNames =
        ref.watch(adminCreatorNamesProvider).valueOrNull ?? {};
    final userRepo = ref.read(userRepositoryProvider);
    return Stack(
      children: [
        adminsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (admins) {
            if (admins.isEmpty) {
              return const Center(
                child: Text('No admins yet. Tap + to add one.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: admins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AdminCard(
                admin: admins[i],
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
          child: FloatingActionButton.extended(
            heroTag: 'fab_add_admin',
            onPressed: () => _showAddAdminSheet(context, ref),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Admin'),
          ),
        ),
      ],
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

  const _AdminCard({
    required this.admin,
    required this.school,
    required this.creatorName,
    required this.userRepository,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isManager = admin.canCreateAdmin;

    return Card(
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: AppColors.adminColor,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(admin.mobile),
              if (isManager)
                const Text(
                  'Admin Manager · Can create admins',
                  style: TextStyle(
                    color: AppColors.adminColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
                onChanged: isManager
                    ? null // already the manager — tap is a no-op
                    : (value) async {
                        if (!value) return; // ignore turning off directly
                        if (school == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('School not loaded yet')),
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
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('NO'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
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
                          if (!context.mounted) return;
                          Future.microtask(() {
                            ref.invalidate(schoolAdminsProvider);
                          });
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update')),
                            );
                          }
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final result = await _showEditAdminDialog(context);
                  if (result == null) return;
                  if (school == null ||
                      (school!.shortName ?? '').isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('School short name not set')),
                      );
                    }
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
                    if (!context.mounted) return;
                    Future.microtask(() {
                      ref.refresh(schoolAdminsProvider);
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: () => _showDeleteDialog(context),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
            Text('Add Admin', style: Theme.of(context).textTheme.titleLarge),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Admin'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── School Profile Tab ────────────────────────────────────────────────────────

class _SchoolProfileTab extends ConsumerStatefulWidget {
  const _SchoolProfileTab();

  @override
  ConsumerState<_SchoolProfileTab> createState() => _SchoolProfileTabState();
}

class _SchoolProfileTabState extends ConsumerState<_SchoolProfileTab> {
  // User name section
  final _userNameKey = GlobalKey<FormState>();
  final _userNameCtrl = TextEditingController();
  bool _nameInitialized = false;
  bool _savingName = false;

  // School details section
  final _schoolFormKey = GlobalKey<FormState>();
  final _schoolNameCtrl = TextEditingController();
  final _schoolMobileCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  bool _schoolInitialized = false;
  bool _savingSchool = false;

  // Logo section
  XFile? _pickedImage;
  ImageResult? _pickedImageResult;
  bool _uploadingLogo = false;

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _schoolNameCtrl.dispose();
    _schoolMobileCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  void _populateName(UserModel user) {
    if (_nameInitialized) return;
    _userNameCtrl.text = user.name;
    _nameInitialized = true;
  }

  void _populateSchool(SchoolModel school) {
    if (_schoolInitialized) return;
    _schoolNameCtrl.text = school.name;
    _schoolMobileCtrl.text = school.mobile ?? '';
    _shortNameCtrl.text = school.shortName ?? '';
    _schoolInitialized = true;
  }

  Future<void> _saveName(String userId) async {
    if (!_userNameKey.currentState!.validate()) return;
    setState(() => _savingName = true);
    try {
      final updatedUser = await ref.read(userRepositoryProvider).updateUserName(
            userId,
            _userNameCtrl.text.trim(),
          );
      _nameInitialized = false;
      ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveSchool(String schoolId, {required bool shortNameEnabled}) async {
    if (!_schoolFormKey.currentState!.validate()) return;
    setState(() => _savingSchool = true);
    try {
      await ref.read(schoolRepositoryProvider).updateSchool(
            schoolId,
            name: _schoolNameCtrl.text.trim(),
            mobile: _schoolMobileCtrl.text.trim().isEmpty
                ? null
                : _schoolMobileCtrl.text.trim(),
            shortName: shortNameEnabled
                ? _shortNameCtrl.text.trim()
                : null,
          );
      _schoolInitialized = false;
      if (mounted) {
        Future.microtask(() {
          ref.invalidate(currentSchoolProvider);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School details updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingSchool = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
      return;
    }

    if (!mounted) return;
    final sizeOk = await validateImageSize(context, file);
    if (!sizeOk) return;

    try {
      final result = await validateAndCompressImage(file);
      if (mounted) {
        setState(() {
          _pickedImage = file;
          _pickedImageResult = result;
        });
      }
    } on ImageValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _uploadLogo(String schoolId) async {
    if (_pickedImage == null || _pickedImageResult == null) return;
    setState(() => _uploadingLogo = true);
    try {
      await ref.read(schoolRepositoryProvider).uploadSchoolLogo(
            schoolId,
            _pickedImageResult!.bytes,
            _pickedImageResult!.mimeType,
          );

      setState(() {
        _pickedImage = null;
        _pickedImageResult = null;
      });
      _schoolInitialized = false;
      if (mounted) {
        Future.microtask(() {
          ref.invalidate(currentSchoolProvider);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final schoolAsync = ref.watch(currentSchoolProvider);
    final usersCountAsync = ref.watch(schoolUsersCountProvider);
    final authState = ref.watch(authNotifierProvider);

    if (userAsync.isLoading || schoolAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userAsync.hasError) {
      return Center(child: Text('Error: ${userAsync.error}'));
    }
    if (schoolAsync.hasError) {
      return Center(child: Text('Error: ${schoolAsync.error}'));
    }

    // Dev-mode fallback: currentUserProvider returns null when there is no
    // Supabase session (phone/OTP login). Use the user stored in authNotifier.
    final user = userAsync.valueOrNull ??
        (authState is AuthSuccess ? authState.user : null);
    final school = schoolAsync.valueOrNull;
    // Use skipLoadingOnRefresh: false so that a reload with stale previous
    // data does NOT keep the field disabled while the new count is in flight.
    final shortNameEnabled = usersCountAsync.when(
      skipLoadingOnRefresh: false,
      data: (count) => count == 0,
      loading: () => true, // optimistically enabled while waiting for count
      error: (_, __) => false,
    );
    dev.log(
      '[Dashboard] schoolUsersCount '
      'isLoading=${usersCountAsync.isLoading} '
      'isRefreshing=${usersCountAsync.isRefreshing} '
      'hasValue=${usersCountAsync.hasValue} '
      'value=${usersCountAsync.valueOrNull} '
      'shortNameEnabled=$shortNameEnabled',
      name: 'short_name',
    );

    if (user != null) _populateName(user);
    if (school != null) _populateSchool(school);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── My Profile ──────────────────────────────────────────────────
          _SectionCard(
            title: 'My Profile',
            icon: Icons.person_outline,
            child: Form(
              key: _userNameKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _userNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.mobile ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Mobile (cannot be changed)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _savingName || user == null
                        ? null
                        : () => _saveName(user.id),
                    icon: _savingName
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Name'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── School Details ───────────────────────────────────────────────
          _SectionCard(
            title: 'School Details',
            icon: Icons.school_outlined,
            child: Form(
              key: _schoolFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _schoolNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'School Name',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _schoolMobileCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shortNameCtrl,
                    enabled: shortNameEnabled,
                    decoration: InputDecoration(
                      labelText: 'School Short Name',
                      prefixIcon: const Icon(Icons.short_text_outlined),
                      helperText: shortNameEnabled
                          ? 'Lowercase letters and numbers only (4–12 chars)'
                          : 'Short name cannot be changed after users are created',
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.text,
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Required';
                      if (val.length < 4) return 'Minimum 4 characters';
                      if (val.length > 12) return 'Maximum 12 characters';
                      if (!RegExp(r'^[a-z0-9]+$').hasMatch(val)) {
                        return 'Lowercase letters and numbers only, no spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _savingSchool || school == null
                        ? null
                        : () => _saveSchool(school.id, shortNameEnabled: shortNameEnabled),
                    icon: _savingSchool
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Details'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── School Logo ──────────────────────────────────────────────────
          _SectionCard(
            title: 'School Logo',
            icon: Icons.image_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LogoPreview(
                  currentUrl: school?.logoUrl,
                  pickedImage: _pickedImage,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _uploadingLogo ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Select Image'),
                ),
                if (_pickedImage != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _uploadingLogo || school == null
                        ? null
                        : () => _uploadLogo(school.id),
                    icon: _uploadingLogo
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Upload Logo'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  final String? currentUrl;
  final XFile? pickedImage;

  const _LogoPreview({this.currentUrl, this.pickedImage});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (pickedImage != null) {
      imageWidget = Image.file(
        File(pickedImage!.path),
        height: 120,
        fit: BoxFit.contain,
      );
    } else if (currentUrl != null && currentUrl!.isNotEmpty) {
      imageWidget = Image.network(
        currentUrl!,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          size: 60,
          color: Colors.grey,
        ),
      );
    } else {
      imageWidget = const Icon(
        Icons.add_photo_alternate_outlined,
        size: 60,
        color: Colors.grey,
      );
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(60)),
      ),
      child: Center(child: imageWidget),
    );
  }
}

// ── School Overview Tab ───────────────────────────────────────────────────────

class _SchoolOverviewTab extends ConsumerWidget {
  const _SchoolOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(schoolOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (overview) => ListView(
        physics: const BouncingScrollPhysics(), // ✅ iOS smooth scroll
        padding: const EdgeInsets.all(16),
        children: [
          _StatsGrid(overview: overview),
          if (overview.studentsPerClass.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Students per Class',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...overview.studentsPerClass.entries.map(
              (e) => _ClassRow(classId: e.key, count: e.value),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  final SchoolOverview overview;
  const _StatsGrid({required this.overview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(schoolAdminsProvider);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Total Students',
          value: '${overview.totalStudents}',
          icon: Icons.people,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Classes',
          value: '${overview.studentsPerClass.length}',
          icon: Icons.class_,
          color: AppColors.coordinatorColor,
        ),
        _StatCard(
          label: 'Total Staff',
          value: '${overview.totalStaff}',
          icon: Icons.badge,
          color: AppColors.staffColor,
        ),
        _StatCard(
          label: 'Total Admins',
          value: adminsAsync.when(
            data: (admins) => '${admins.length}',
            loading: () => '...',
            error: (_, __) => '?',
          ),
          icon: Icons.admin_panel_settings,
          color: AppColors.adminColor,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final String classId;
  final int count;
  const _ClassRow({required this.classId, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading:
            const Icon(Icons.class_, color: AppColors.coordinatorColor),
        title: Text('Class: $classId'),
        trailing: Chip(label: Text('$count students')),
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
