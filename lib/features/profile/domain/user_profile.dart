class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.secondName,
    required this.lastName,
    required this.secondLastName,
    required this.birthDate,
    required this.bloodType,
    required this.gender,
    required this.department,
    required this.city,
    this.address,
    this.phone,
  });

  final String firstName;
  final String secondName;
  final String lastName;
  final String secondLastName;
  final DateTime? birthDate;
  final String bloodType;
  final String gender;
  final String department;
  final String city;
  final String? address;
  final String? phone;
}
