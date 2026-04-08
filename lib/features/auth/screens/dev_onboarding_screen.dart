// TODO: Disable dev login before production
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../router/app_router.dart';
import '../auth_notifier.dart';
import '../auth_state.dart';

/// Dev-mode onboarding screen.
/// Shown when a mobile number is not found in the [users] table.
/// Creates a school + super_user record and navigates to the dashboard.
class DevOnboardingScreen extends ConsumerStatefulWidget {
  const DevOnboardingScreen({super.key});

  @override
  ConsumerState<DevOnboardingScreen> createState() =>
      _DevOnboardingScreenState();
}

class _DevOnboardingScreenState extends ConsumerState<DevOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! DevNewUser) return;

    ref.read(authNotifierProvider.notifier).devOnboard(
          name: _nameController.text.trim(),
          mobile: authState.mobile,
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

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final mobile =
        authState is DevNewUser ? authState.mobile : '';

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

                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 32),

                Text(
                  'Complete your profile',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re a new user. Enter your name to set up your school and account.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 16),

                // Mobile (read-only, for reference)
                if (mobile.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          mobile,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => Validators.required(v, 'Your name'),
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'e.g. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 24),

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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
