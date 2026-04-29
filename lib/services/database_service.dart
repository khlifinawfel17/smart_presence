import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _studentsKey = 'students';
  static const String _attendanceKey = 'attendance';

  Future<List<Student>> getAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studentsKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Student.fromMap(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));
  }

  Future<void> insertStudent(Student student) async {
    final students = await getAllStudents();
    final newId = DateTime.now().millisecondsSinceEpoch;
    students.add(Student(
      id: newId,
      nom: student.nom,
      prenom: student.prenom,
      classe: student.classe,
      groupe: student.groupe,
    ));
    await _saveStudents(students);
  }

  Future<void> deleteStudent(int id) async {
    final students = await getAllStudents();
    students.removeWhere((s) => s.id == id);
    await _saveStudents(students);
    final records = await getAllAttendanceHistory();
    await _saveAttendance(records.where((r) => r.studentId != id).toList());
  }

  Future<void> _saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentsKey, jsonEncode(students.map((s) => s.toMap()).toList()));
  }

  Future<void> saveAttendanceSession(List<Student> students, String sessionLabel) async {
    final existing = await getAllAttendanceHistory();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    int idCounter = DateTime.now().millisecondsSinceEpoch;
    for (final student in students) {
      existing.add(AttendanceRecord(
        id: idCounter++,
        studentId: student.id!,
        studentName: student.fullName,
        classe: student.classe,
        groupe: student.groupe,
        isPresent: student.isPresent,
        date: date,
        sessionLabel: sessionLabel,
      ));
    }
    await _saveAttendance(existing);
  }

  Future<List<AttendanceRecord>> getAllAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attendanceKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    final records = decoded
        .map((e) => AttendanceRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<Map<String, List<AttendanceRecord>>> getHistoryGroupedBySession() async {
    final records = await getAllAttendanceHistory();
    final Map<String, List<AttendanceRecord>> grouped = {};
    for (final record in records) {
      final key = '${record.sessionLabel} — ${record.date}';
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return grouped;
  }

  Future<void> _saveAttendance(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attendanceKey, jsonEncode(records.map((r) => r.toMap()).toList()));
  }
}