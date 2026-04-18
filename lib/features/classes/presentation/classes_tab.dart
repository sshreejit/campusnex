import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/theme/app_colors.dart';

import '../providers/class_provider.dart';
import '../repositories/class_repository.dart';
import '../models/class_model.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

class ClassesTab extends ConsumerWidget {
  const ClassesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Stack(
      children: [
        Container(
          color: AppColors.background,
          child: classesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e'),
            ),
            data: (classes) {
              if (classes.isEmpty) {
                return const Center(child: Text('No classes found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: classes.length,
                itemBuilder: (_, i) {
                  final c = classes[i];

                  return Card(
                    child: ListTile(
                      title: Text(
                        c.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// ✏️ EDIT
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showAddEditDialog(context, ref, classModel: c),
                          ),

                          /// 🗑 DELETE
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () async {
                              final auth = ref.read(authNotifierProvider);
                              if (auth is! AuthSuccess) return;

                              final confirmed = await showConfirmDialog(
                                context: context,
                                title: 'Delete Class',
                                message:
                                'Are you sure you want to delete this class?',
                                actionText: 'Delete',
                                isDestructive: true,
                              );

                              if (confirmed != true) return;

                              await ref
                                  .read(classRepositoryProvider)
                                  .deleteClass(
                                id: c.id,
                                schoolId: auth.user.schoolId,
                              );

                              ref.refresh(classesProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        /// ➕ FAB
        Positioned(
          bottom: 0,
          right: 0,
          child: AppFab(
            label: 'Add Class',
            icon: Icons.add,
            onTap: () => _showAddEditDialog(context, ref),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ADD / EDIT DIALOG
  // ─────────────────────────────────────────────
  void _showAddEditDialog(
      BuildContext context,
      WidgetRef ref, {
        ClassModel? classModel,
      }) {
    final classController =
    TextEditingController(text: classModel?.className ?? '');
    final sectionController =
    TextEditingController(text: classModel?.section ?? '');

    final isEdit = classModel != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Class' : 'Add Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: classController,
              decoration: const InputDecoration(labelText: 'Class'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sectionController,
              decoration: const InputDecoration(labelText: 'Section'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final className = classController.text.trim();
              final section = sectionController.text.trim();

              if (className.isEmpty || section.isEmpty) return;

              final auth = ref.read(authNotifierProvider);
              if (auth is! AuthSuccess) return;

              if (isEdit) {
                await ref.read(classRepositoryProvider).updateClass(
                  id: classModel.id,
                  className: className,
                  section: section,
                  schoolId: auth.user.schoolId,
                );
              } else {
                final result =
                await ref.read(classRepositoryProvider).addClass(
                  className: className,
                  section: section,
                  schoolId: auth.user.schoolId,
                );

                if (!result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.error ?? 'Error')),
                  );
                  return;
                }
              }

              ref.refresh(classesProvider);
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}