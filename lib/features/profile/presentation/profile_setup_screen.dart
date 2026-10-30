import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../data/medical_profile_repository.dart';
import 'personal_info_screen.dart';
import 'medical_profile_screen.dart';

/// Registro en dos pantallas independientes: datos personales y ficha médica.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    required this.profileRepository,
    required this.medicalProfileRepository,
    this.isRequiredFlow = false,
    this.onRequiredComplete,
    super.key,
  });
  final ProfileRepository profileRepository;
  final ApiMedicalProfileRepository medicalProfileRepository;
  final bool isRequiredFlow;
  final VoidCallback? onRequiredComplete;
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _medicalStep = false;
  @override
  Widget build(BuildContext context) => _medicalStep
      ? MedicalProfileScreen(
          repository: widget.medicalProfileRepository,
          isRequiredFlow: true,
          onRequiredComplete: widget.onRequiredComplete,
        )
      : PersonalInfoScreen(
          repository: widget.profileRepository,
          isRequiredFlow: true,
          onRequiredComplete: () => setState(() => _medicalStep = true),
        );
}
