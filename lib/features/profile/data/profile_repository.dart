import '../domain/user_profile.dart';
import '../../../core/network/api_client.dart';

/// Profile storage contract. Replace the session implementation with the API adapter.
abstract interface class ProfileRepository {
  UserProfile? get profile;
  Future<void> save(UserProfile profile);
}

/// Temporary volatile storage for UI development; data is lost when the app closes.
class SessionProfileRepository implements ProfileRepository {
  UserProfile? _profile;

  @override
  UserProfile? get profile => _profile;

  @override
  Future<void> save(UserProfile profile) async {
    _profile = profile;
  }
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this.api);
  final ApiClient api;
  UserProfile? _profile;
  String? loadError;
  @override
  UserProfile? get profile => _profile;

  Future<void> load() async {
    loadError = null;
    try {
      final row = await api.get('/me') as Map<String, dynamic>;
      _profile = UserProfile(
        firstName: row['first_name'] as String? ?? '',
        secondName: row['second_name'] as String? ?? '',
        lastName: row['last_name'] as String? ?? '',
        secondLastName: row['second_last_name'] as String? ?? '',
        birthDate: DateTime.tryParse(row['birth_date']?.toString() ?? ''),
        bloodType: row['blood_type'] as String? ?? '',
        gender: row['gender'] as String? ?? '',
        department: row['department'] as String? ?? '',
        city: row['city'] as String? ?? '',
        address: row['address'] as String?,
        phone: row['phone'] as String?,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _profile = null;
        return;
      }
      loadError = error.message;
      rethrow;
    } catch (error) {
      loadError = error.toString();
      rethrow;
    }
  }

  @override
  Future<void> save(UserProfile profile) async {
    await api.patch(
      '/me',
      body: {
        'firstName': profile.firstName,
        'secondName': profile.secondName,
        'lastName': profile.lastName,
        'secondLastName': profile.secondLastName,
        'birthDate': profile.birthDate?.toIso8601String().split('T').first,
        'bloodType': profile.bloodType == 'No lo sé' ? null : profile.bloodType,
        'gender': profile.gender,
        'department': profile.department,
        'city': profile.city,
        'address': profile.address,
        'phone': profile.phone,
      },
    );
    _profile = profile;
    loadError = null;
  }
}
