import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class AttendancePage extends StatefulWidget {
  final List<Student> students;

  const AttendancePage({super.key, required this.students});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseService _db = DatabaseService();
  late List<Student> _students;
  bool _isSaving = false;
  String _sessionLabel = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Copier la liste pour éviter de modifier l'original
    _students = widget.students.map((s) => Student(
      id: s.id,
      nom: s.nom,
      prenom: s.prenom,
      classe: s.classe,
      groupe: s.groupe,
      isPresent: false,
    )).toList();

    // Label de session par défaut
    final now = DateTime.now();
    _sessionLabel =
    'Séance du ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) =>
    s.fullName.toLowerCase().contains(q) ||
        s.classe.toLowerCase().contains(q) ||
        s.groupe.toLowerCase().contains(q)).toList();
  }

  int get _presentCount => _students.where((s) => s.isPresent).length;
  int get _absentCount => _students.length - _presentCount;

  void _toggleAll(bool value) {
    setState(() {
      for (var student in _students) {
        student.isPresent = value;
      }
    });
  }

  Future<void> _saveSession() async {
    if (_sessionLabel.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un intitulé de séance'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sauvegarder la séance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session : $_sessionLabel'),
            const SizedBox(height: 8),
            Text('Présents : $_presentCount / ${_students.length}'),
            Text('Absents : $_absentCount / ${_students.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _db.saveAttendanceSession(_students, _sessionLabel.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Séance sauvegardée avec succès !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gestion des présences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _toggleAll(true),
            child: const Text('Tous', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _toggleAll(false),
            child: const Text('Aucun', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionHeader(),
          _buildStatsBar(),
          _buildSearchBar(),
          Expanded(child: _buildStudentList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSession,
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _sessionLabel = v),
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: _sessionLabel,
                  selection: TextSelection.collapsed(offset: _sessionLabel.length),
                ),
              ),
              decoration: const InputDecoration(
                hintText: 'Intitulé de la séance...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Présents',
              count: _presentCount,
              color: const Color(0xFF2E7D32),
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Absents',
              count: _absentCount,
              color: Colors.red.shade700,
              icon: Icons.cancel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Total',
              count: _students.length,
              color: const Color(0xFF1565C0),
              icon: Icons.people,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un étudiant...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filtered = _filteredStudents;
    if (filtered.isEmpty) {
      return const Center(child: Text('Aucun étudiant trouvé'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final student = filtered[index];
        return _buildAttendanceCard(student);
      },
    );
  }

  Widget _buildAttendanceCard(Student student) {
    // Trouver l'index réel dans _students pour toggle
    final realIndex = _students.indexWhere((s) => s.id == student.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (realIndex != -1) {
            setState(() => _students[realIndex].isPresent = !_students[realIndex].isPresent);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar avec initiales
              CircleAvatar(
                radius: 22,
                backgroundColor: student.isPresent
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade300,
                child: Text(
                  '${student.prenom[0]}${student.nom[0]}'.toUpperCase(),
                  style: TextStyle(
                    color: student.isPresent ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.classe} • ${student.groupe}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: student.isPresent
                      ? const Color(0xFF2E7D32).withOpacity(0.12)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: student.isPresent
                        ? const Color(0xFF2E7D32).withOpacity(0.4)
                        : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  student.isPresent ? 'Présent' : 'Absent',
                  style: TextStyle(
                    color: student.isPresent
                        ? const Color(0xFF2E7D32)
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: student.isPresent,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) {
                  if (realIndex != -1) {
                    setState(() => _students[realIndex].isPresent = val ?? false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}