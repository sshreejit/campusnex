import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../router/app_router.dart';
import '../auth_notifier.dart';
import '../auth_state.dart';

class SetupSchoolScreen extends ConsumerStatefulWidget {
  const SetupSchoolScreen({super.key});

  @override
  ConsumerState<SetupSchoolScreen> createState() => _SetupSchoolScreenState();
}

class _SetupSchoolScreenState extends ConsumerState<SetupSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _userNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authNotifierProvider.notifier).setupSchoolAndUser(
          schoolName: _schoolNameController.text.trim(),
          userName: _userNameController.text.trim(),
          mobile: _mobileController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFlowState>(authNotifierProvider, (_, next) {
      if (next is AuthSuccess) {
        context.go(AppRoutes.forRole(next.user.role));
      } else if (next is AuthFlowError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.domain_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 32),

                Text('Set up your school',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'You\'re the first user — you\'ll be the Super Admin of your school.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 40),

                // School name
                TextFormField(
                  controller: _schoolNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'School name'),
                  decoration: const InputDecoration(
                    labelText: 'School / Institution Name',
                    hintText: 'e.g. Sunrise Public School',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Your name
                TextFormField(
                  controller: _userNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Your name'),
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'e.g. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),

                const SizedBox(height: 16),

                // Mobile
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Complete Setup'),
                ),

                const SizedBox(height: 24),

                // Role info chip
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.superUserColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 14, color: AppColors.superUserColor),
                        const SizedBox(width: 6),
                        Text(
                          'You will be assigned Super Admin role',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.superUserColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
