class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String status;
  final DateTime? lastSeen;
  final double? rating;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.status,
    this.lastSeen,
    this.rating,
  });
}
