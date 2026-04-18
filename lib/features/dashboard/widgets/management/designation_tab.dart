import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../auth/auth_notifier.dart';
import '../../../auth/auth_state.dart';
import '../../../designations/models/designation_model.dart';
import '../../../designations/providers/designation_provider.dart';
import '../../../designations/repositories/designation_repository.dart';

class DesignationTab extends ConsumerWidget {
  const DesignationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designationsAsync = ref.watch(designationsProvider);

    return Stack(
      children: [
        Container(
          color: AppColors.background,
          child: designationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (designations) {
              if (designations.isEmpty) {
                return const Center(
                  child: Text(
                    'No designations found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: designations.length,
                itemBuilder: (_, i) {
                  final d = designations[i];

                  return Card(
                    color: AppColors.surface,
                    child: ListTile(
                      title: Text(
                        d.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          /// ✏️ EDIT
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditDialog(context, ref, d),
                          ),

                          /// 🗑️ DELETE
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () async {

                              print("Deleting ID: ${d.id}");

                              final isUsed = await ref
                                  .read(designationRepositoryProvider)
                                  .isDesignationUsed(d.id);

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Designation'),
                                  content: Text(
                                    isUsed
                                        ? 'This designation is assigned to staff.\n\nDeleting it will remove it from those staff.\n\nContinue?'
                                        : 'Are you sure you want to delete this designation?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              final result = await ref
                                  .read(designationRepositoryProvider)
                                  .deleteDesignation(id: d.id);

                              if (!context.mounted) return;

                              if (result.success) {
                                ref.refresh(designationsProvider);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Deleted')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.error ?? 'Error')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  );
                },
              );
            },
          ),
        ),

        /// ➕ ADD BUTTON
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_add_designation',
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Designation'),
          ),
        ),
      ],
    );
  }
  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Designation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a name')),
                );
                return;
              }

              final authState = ref.read(authNotifierProvider);

              if (authState is! AuthSuccess) return;

              final user = authState.user;

              final result = await ref
                  .read(designationRepositoryProvider)
                  .addDesignation(
                name: name,
                schoolId: user.schoolId,
              );

              if (!context.mounted) return;

              if (result.success) {
                ref.refresh(designationsProvider);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error ?? 'Error')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  void _showEditDialog(
      BuildContext context,
      WidgetRef ref,
      DesignationModel d,
      ) {
    final controller = TextEditingController(text: d.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Designation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
          onPressed: () async {
    final name = controller.text.trim();

    if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Enter a name')),
    );
    return;
    }

    final isUsed = await ref
        .read(designationRepositoryProvider)
        .isDesignationUsed(d.id);

    if (isUsed) {
    final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
    title: const Text('Update Designation'),
    content: const Text(
    'This designation is already assigned to staff.\n\nUpdating it will affect them.\n\nContinue?',
    ),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context, false),
    child: const Text('Cancel'),
    ),
    FilledButton(
    onPressed: () => Navigator.pop(context, true),
    child: const Text('Continue'),
    ),
    ],
    ),
    );

    if (confirm != true) return;
    }

    final result = await ref
        .read(designationRepositoryProvider)
        .updateDesignation(
    id: d.id,
    name: name,
    );

    if (!context.mounted) return;

    if (result.success) {
    ref.refresh(designationsProvider);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Updated')),
    );
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.error ?? 'Error')),
    );
    }
    },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

}