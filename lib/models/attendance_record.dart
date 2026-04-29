class AttendanceRecord {
  final int? id;
  final int studentId;
  final String studentName;
  final String classe;
  final String groupe;
  final bool isPresent;
  final String date;
  final String sessionLabel;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.classe,
    required this.groupe,
    required this.isPresent,
    required this.date,
    required this.sessionLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'classe': classe,
      'groupe': groupe,
      'is_present': isPresent ? 1 : 0,
      'date': date,
      'session_label': sessionLabel,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      studentName: map['student_name'] as String,
      classe: map['classe'] as String,
      groupe: map['groupe'] as String,
      isPresent: (map['is_present'] as int) == 1,
      date: map['date'] as String,
      sessionLabel: map['session_label'] as String,
    );
  }
}