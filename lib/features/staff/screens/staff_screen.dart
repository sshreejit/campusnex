import 'dart:typed_data';

import '../../../core/repositories/user_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/staff_model.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../roles/models/role_model.dart';
import '../repositories/staff_repository.dart';
import '../repositories/staff_roles_repository.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool? _statusFilter; // null = all, true = active, false = inactive
  String? _designationFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StaffModel> _applyFilters(List<StaffModel> staffList) {
    return staffList.where((staff) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          staff.name.toLowerCase().contains(q) ||
          staff.mobile.toLowerCase().contains(q) ||
          staff.empcode.toLowerCase().contains(q);

      final matchesStatus =
          _statusFilter == null || staff.isActive == _statusFilter;

      final matchesDesignation =
          _designationFilter == null || staff.designation == _designationFilter;

      return matchesSearch && matchesStatus && matchesDesignation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (staffList) {
          final designations = staffList
              .map((s) => s.designation)
              .toSet()
              .toList()
            ..sort();

          final filtered = _applyFilters(staffList);

          return Column(
            children: [
              _SearchFilterBar(
                searchCtrl: _searchCtrl,
                statusFilter: _statusFilter,
                designationFilter: _designationFilter,
                designations: designations,
                onSearchChanged: (v) =>
                    setState(() => _searchQuery = v),
                onStatusChanged: (v) =>
                    setState(() => _statusFilter = v),
                onDesignationChanged: (v) =>
                    setState(() => _designationFilter = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No staff found',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _StaffCard(
                          staff: filtered[i],
                          onEdit: () => _showStaffFormSheet(context,
                              staff: filtered[i]),
                          onDelete: () =>
                              _confirmDelete(context, filtered[i], ref),
                          onToggleStatus: (_) =>
                              _toggleStaffStatus(context, filtered[i], ref),
                          onAssignRole: () => _showAssignRoleSheet(
                              context, ref, filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEARCH + FILTER BAR
// ─────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool? statusFilter;
  final String? designationFilter;
  final List<String> designations;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onStatusChanged;
  final ValueChanged<String?> onDesignationChanged;

  const _SearchFilterBar({
    required this.searchCtrl,
    required this.statusFilter,
    required this.designationFilter,
    required this.designations,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDesignationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, mobile, emp code',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Active',
                  selected: statusFilter == true,
                  onTap: () => onStatusChanged(
                    statusFilter == true ? null : true,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  selected: statusFilter == false,
                  onTap: () => onStatusChanged(
                    statusFilter == false ? null : false,
                  ),
                ),
                if (designations.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _DesignationDropdown(
                    value: designationFilter,
                    designations: designations,
                    onChanged: onDesignationChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DesignationDropdown extends StatelessWidget {
  final String? value;
  final List<String> designations;
  final ValueChanged<String?> onChanged;

  const _DesignationDropdown({
    required this.value,
    required this.designations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(16),
        color: value != null
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isDense: true,
          hint: const Text('Designation', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Designations', style: TextStyle(fontSize: 13)),
            ),
            ...designations.map(
              (d) => DropdownMenuItem<String?>(
                value: d,
                child: Text(d, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADD STAFF SHEET
// ─────────────────────────────────────────────

void _showStaffFormSheet(BuildContext context, {StaffModel? staff}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _StaffFormSheet(staff: staff),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  StaffModel staff,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Staff'),
      content: const Text('Are you sure you want to delete this staff?'),
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

  final result = await ref.read(staffRepositoryProvider).deleteStaff(
    staffId: staff.id,
    schoolId: staff.schoolId,
  );

  if (!context.mounted) return;

  if (result.success) {
    ref.invalidate(staffListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff deleted successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Delete failed')),
    );
  }
}

Future<void> _toggleStaffStatus(
  BuildContext context,
  StaffModel staff,
  WidgetRef ref,
) async {
  final result = await ref.read(staffRepositoryProvider).updateStaffStatus(
    staffId: staff.id,
    schoolId: staff.schoolId,
    isActive: !staff.isActive,
  );

  if (!context.mounted) return;

  if (result.success) {
    ref.invalidate(staffListProvider);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Status update failed')),
    );
  }
}

Future<void> _showAssignRoleSheet(
  BuildContext context,
  WidgetRef ref,
  StaffModel staff,
) async {
  final result = await showModalBottomSheet<Result>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AssignRoleSheet(staff: staff),
  );

  if (result == null) return;
  if (!context.mounted) return;

  if (result.success) {
    ref.invalidate(staffRolesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Role assigned successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Failed to assign role')),
    );
  }
}

class _StaffFormSheet extends ConsumerStatefulWidget {
  final StaffModel? staff;
  const _StaffFormSheet({this.staff});

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _empCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  Uint8List? _imageBytes;

  bool get _isEditMode => widget.staff != null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _empCodeCtrl.text = widget.staff!.empcode;
      _nameCtrl.text = widget.staff!.name;
      _designationCtrl.text = widget.staff!.designation;
      _mobileCtrl.text = widget.staff!.mobile;
    }
  }

  @override
  void dispose() {
    _empCodeCtrl.dispose();
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    var user = await ref.read(currentUserProvider.future);
    if (user == null) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthSuccess) user = authState.user;
    }

    if (user == null) {
      setState(() => _error = 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Upload photo if selected
    String? photoUrl;
    if (_imageBytes != null) {
      photoUrl = await ref.read(staffRepositoryProvider).uploadStaffPhoto(
        schoolId: user.schoolId,
        bytes: _imageBytes!,
      );
    }

    final Result result;

    if (_isEditMode) {
      result = await ref.read(staffRepositoryProvider).updateStaff(
        staffId: widget.staff!.id,
        schoolId: user.schoolId,
        empCode: _empCodeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        photoUrl: photoUrl,
      );
    } else {
      final school = await ref.read(currentSchoolProvider.future);
      if (school == null ||
          school.shortName == null ||
          school.shortName!.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'School short name is not configured.';
        });
        return;
      }
      result = await ref.read(staffRepositoryProvider).createStaffWithUser(
        schoolId: user.schoolId,
        schoolShortName: school.shortName!,
        createdBy: user.id,
        empCode: _empCodeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        photoUrl: photoUrl,
      );
    }

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      ref.invalidate(staffListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Staff updated successfully' : 'Staff added successfully',
          ),
        ),
      );
    } else {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditMode ? 'Edit Staff' : 'Add Staff',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Image picker
            Center(
              child: GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (widget.staff?.photoUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.staff!.photoUrl!)
                              : null) as ImageProvider?,
                      child: (_imageBytes == null &&
                              (widget.staff?.photoUrl == null))
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _empCodeCtrl,
              decoration: const InputDecoration(labelText: 'Emp Code'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _designationCtrl,
              decoration: const InputDecoration(labelText: 'Designation'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
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

// ─────────────────────────────────────────────
// STAFF CARD
// ─────────────────────────────────────────────

// ONLY CHANGE: _StaffCard converted to ConsumerWidget + roles display added

class _StaffCard extends ConsumerWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onAssignRole;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onAssignRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔹 Simple session (can improve later)
    String _getCurrentSession() {
      final now = DateTime.now();
      final year = now.year;

      return now.month >= 4
          ? '$year-${year + 1}'
          : '${year - 1}-$year';
    }

    final currentSession = _getCurrentSession();

    final rolesAsync = ref.watch(
      staffRolesProvider(
        StaffRoleParams(
          staffId: staff.id,
          session: currentSession,
          schoolId: staff.schoolId,
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: staff.photoUrl != null
                  ? CachedNetworkImageProvider(staff.photoUrl!)
                  : null,
              child: staff.photoUrl == null
                  ? const Icon(Icons.person, size: 28, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff.empcode,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: staff.isActive,
                        onChanged: onToggleStatus,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(staff.name),

                  const SizedBox(height: 4),

                  // Designation
                  Chip(
                    label: Text(
                      staff.designation,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(staff.mobile),

                  const SizedBox(height: 4),

                  Text(
                    staff.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: staff.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔥 ROLES DISPLAY (NEW)
                  rolesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (roles) {
                      if (roles.isEmpty) return const SizedBox.shrink();

                      return Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children: roles.map((role) {
                          return Chip(
                            label: Text(
                              role.roleName.isNotEmpty
                                  ? role.roleName
                                  : role.roleId,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.blue.shade50,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Assign Role Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onAssignRole,
                      icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                      label: const Text(
                        'Assign Role',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ASSIGN ROLE SHEET
// ─────────────────────────────────────────────

class _AssignRoleSheet extends ConsumerStatefulWidget {
  final StaffModel staff;

  const _AssignRoleSheet({required this.staff});

  @override
  ConsumerState<_AssignRoleSheet> createState() => _AssignRoleSheetState();
}

class _AssignRoleSheetState extends ConsumerState<_AssignRoleSheet> {
  final _sessionCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  RoleModel? _selectedRole;
  bool _loading = false;
  String? _error;

  /// ✅ NEW: Default session logic
  String _getDefaultSession() {
    final now = DateTime.now();
    final year = now.year;

    // Academic year starts in April
    if (now.month >= 4) {
      return '$year-${year + 1}';
    } else {
      return '${year - 1}-$year';
    }
  }

  @override
  void initState() {
    super.initState();

    /// ✅ Auto-fill session
    _sessionCtrl.text = _getDefaultSession();
  }

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedRole == null) {
      setState(() => _error = 'Please select a role');
      return;
    }

    if (_sessionCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Session is required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(staffRolesRepositoryProvider).assignRole(
      staffId: widget.staff.id,
      roleId: _selectedRole!.id,
      session: _sessionCtrl.text.trim(),
      schoolId: widget.staff.schoolId,
      className: _classCtrl.text.trim().isEmpty ? null : _classCtrl.text.trim(),
      section: _sectionCtrl.text.trim().isEmpty ? null : _sectionCtrl.text.trim(),
    );

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assign Role — ${widget.staff.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          rolesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text(
              'Failed to load roles',
              style: TextStyle(color: Colors.red),
            ),
            data: (roles) => DropdownButtonFormField<RoleModel>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: roles
                  .map((r) => DropdownMenuItem(
                value: r,
                child: Text(r.name),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v),
            ),
          ),

          const SizedBox(height: 12),

          /// ✅ Updated label
          TextField(
            controller: _sessionCtrl,
            decoration: const InputDecoration(
              labelText: 'Session (auto-filled)',
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _classCtrl,
            decoration: const InputDecoration(labelText: 'Class (optional)'),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _sectionCtrl,
            decoration: const InputDecoration(labelText: 'Section (optional)'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Assign'),
          ),
        ],
      ),
    );
  }
}