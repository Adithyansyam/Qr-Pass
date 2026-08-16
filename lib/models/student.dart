/// Represents a single student pass record in Supabase.
class Student {
  final String id;         // UUID primary key
  final String passId;     // e.g. ONAM-8F42A91C
  final String name;
  final String className;
  final String? rollNumber;
  final String? department;
  final String status;     // 'pending' | 'approved'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy; // staff user UUID

  const Student({
    required this.id,
    required this.passId,
    required this.name,
    required this.className,
    this.rollNumber,
    this.department,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
  });

  /// Construct from a Supabase row map.
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      passId: map['pass_id'] as String,
      name: map['name'] as String,
      className: map['class_name'] as String,
      rollNumber: map['roll_number'] as String?,
      department: map['department'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      approvedBy: map['approved_by'] as String?,
    );
  }

  /// Convert to a map suitable for Supabase insert (excludes server-set fields).
  Map<String, dynamic> toInsertMap() {
    return {
      'pass_id': passId,
      'name': name,
      'class_name': className,
      if (rollNumber != null) 'roll_number': rollNumber,
      if (department != null) 'department': department,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  Student copyWith({
    String? status,
    DateTime? approvedAt,
    String? approvedBy,
  }) {
    return Student(
      id: id,
      passId: passId,
      name: name,
      className: className,
      rollNumber: rollNumber,
      department: department,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}
