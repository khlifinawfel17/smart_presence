class Student {
  final int? id;
  final String nom;
  final String prenom;
  final String classe;
  final String groupe;
  bool isPresent;

  Student({
    this.id,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.groupe,
    this.isPresent = false,
  });

  /// Convertir un étudiant en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'classe': classe,
      'groupe': groupe,
    };
  }

  /// Créer un étudiant depuis une Map SQLite
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      classe: map['classe'] as String,
      groupe: map['groupe'] as String,
    );
  }

  /// Nom complet de l'étudiant
  String get fullName => '$prenom $nom';

  @override
  String toString() {
    return 'Student{id: $id, nom: $nom, prenom: $prenom, classe: $classe, groupe: $groupe}';
  }
}