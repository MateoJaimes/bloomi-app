class MedicalProfile {
  const MedicalProfile({
    this.medications = '',
    this.conditions = '',
    this.allergies = '',
    this.isCompleted = false,
  });

  final String medications;
  final String conditions;
  final String allergies;
  final bool isCompleted;
}
