class ClassModel {
  final String id;
  final String className;
  final String section;
  final String schoolId;
  final bool isActive;

  ClassModel({
    required this.id,
    required this.className,
    required this.section,
    required this.schoolId,
    required this.isActive,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      className: map['class_name'],
      section: map['section'],
      schoolId: map['school_id'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_name': className,
      'section': section,
      'school_id': schoolId,
      'is_active': isActive,
    };
  }

  String get displayName => '$className $section';
}