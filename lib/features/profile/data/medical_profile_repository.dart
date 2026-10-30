import '../../../core/network/api_client.dart';
import '../domain/medical_profile.dart';

class ApiMedicalProfileRepository {
  ApiMedicalProfileRepository(this.api);

  final ApiClient api;
  MedicalProfile profile = const MedicalProfile();

  Future<void> load() async {
    final row = await api.get('/me/medical') as Map<String, dynamic>;
    profile = MedicalProfile(
      medications: row['medications'] as String? ?? '',
      conditions: row['conditions'] as String? ?? '',
      allergies: row['allergies'] as String? ?? '',
      isCompleted: row['is_completed'] as bool? ?? false,
    );
  }

  Future<void> save(MedicalProfile value) async {
    await api.patch(
      '/me/medical',
      body: {
        'medications': value.medications.trim(),
        'conditions': value.conditions.trim(),
        'allergies': value.allergies.trim(),
      },
    );
    profile = MedicalProfile(
      medications: value.medications.trim(),
      conditions: value.conditions.trim(),
      allergies: value.allergies.trim(),
      isCompleted: true,
    );
  }
}
