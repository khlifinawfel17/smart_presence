import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  bool _isSaving = false;

  final List<String> _classes = [
    'L1 Informatique', 'L2 Informatique', 'L3 Informatique',
    'M1 Informatique', 'M2 Informatique',

  ];
  final List<String> _groupes = ['G1', 'G2', 'G3', 'G4', 'G5'];

  String? _selectedClasse;
  String? _selectedGroupe;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClasse == null || _selectedGroupe == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une classe et un groupe'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final student = Student(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        classe: _selectedClasse!,
        groupe: _selectedGroupe!,
      );
      await _db.insertStudent(student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${student.fullName} ajouté avec succès !'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nomController.clear();
    _prenomController.clear();
    setState(() { _selectedClasse = null; _selectedGroupe = null; });
  }

  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
    filled: true,
    fillColor: const Color(0xFFF0F4FF),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ajouter un étudiant'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.white24,
                  child: Icon(Icons.person_add, color: Colors.white, size: 30)),
              SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nouvel étudiant', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Remplissez le formulaire ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Section personnelle
            _sectionTitle('Informations personnelles', Icons.person),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prenomController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDeco('Prénom', Icons.badge_outlined),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Prénom requis (min 2 caractères)' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nomController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDeco('Nom', Icons.badge),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Nom requis (min 2 caractères)' : null,
            ),
            const SizedBox(height: 24),

            // Section académique
            _sectionTitle('Informations académiques', Icons.school),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedClasse,
              decoration: _fieldDeco('Classe', Icons.class_),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedClasse = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedGroupe,
              decoration: _fieldDeco('Groupe', Icons.group),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              items: _groupes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _selectedGroupe = v),
            ),
            const SizedBox(height: 32),

            // Boutons
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  foregroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
              )),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF1565C0), size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: const Color(0xFF1565C0).withOpacity(0.3))),
    ]);
  }
}