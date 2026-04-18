import 'dart:io';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/school_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/school_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/utils/image_utils.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

import '../providers/dashboard_providers.dart';

class SchoolProfileTab extends ConsumerStatefulWidget {
  const SchoolProfileTab();

  @override
  ConsumerState<SchoolProfileTab> createState() => SchoolProfileTabState();
}

class SchoolProfileTabState extends ConsumerState<SchoolProfileTab> {
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

    return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
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
      color: AppColors.surface, elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(
              height: 24,
              color: AppColors.divider,
            ),
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
          color: AppColors.textSecondary,
        ),
      );
    } else {
      imageWidget = const Icon(
        Icons.add_photo_alternate_outlined,
        size: 60,
        color: AppColors.textSecondary,
      );
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: imageWidget),
    );
  }
}