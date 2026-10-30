import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/medical_profile_repository.dart';
import '../../profile/domain/medical_profile.dart';
import '../../profile/presentation/personal_info_screen.dart';
import '../../profile/presentation/medical_profile_screen.dart';
import '../../questionnaire/data/health_questionnaire_repository.dart';
import '../../questionnaire/presentation/health_questionnaire_screen.dart';
import '../../rewards/data/rewards_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onFindCenters,
    required this.onShowImpact,
    required this.onLogout,
    required this.api,
    required this.profileRepository,
    required this.medicalProfileRepository,
    required this.questionnaireRepository,
    required this.rewardsRepository,
    super.key,
  });

  final VoidCallback onFindCenters;
  final VoidCallback onShowImpact;
  final VoidCallback onLogout;
  final ApiClient api;
  final ProfileRepository profileRepository;
  final ApiMedicalProfileRepository medicalProfileRepository;
  final HealthQuestionnaireRepository questionnaireRepository;
  final RewardsRepository rewardsRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _donationCount = 0;
  @override
  void initState() {
    super.initState();
    _loadDonationCount();
  }

  Future<void> _loadDonationCount() async {
    try {
      final rows = await widget.api.get('/me/donations') as List;
      if (mounted) {
        setState(
          () => _donationCount = rows
              .where(
                (row) => (row as Map<String, dynamic>)['donated_at'] != null,
              )
              .length,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileRepository.profile;
    final greetingName = profile == null
        ? 'donante'
        : [
            profile.firstName.trim(),
            profile.lastName.trim(),
          ].where((part) => part.isNotEmpty).join(' ');
    final bloodType = profile?.bloodType.isNotEmpty == true
        ? profile!.bloodType
        : 'Sin registrar';

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 128),
      children: [
        _DonorHeader(
          name: greetingName.isEmpty ? 'donante' : greetingName,
          bloodType: bloodType,
          onEditProfile: _editPersonalInfo,
          onLogout: _confirmLogout,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _SectionHeading(title: 'Tu impacto')),
                  TextButton.icon(
                    onPressed: widget.onShowImpact,
                    icon: const Icon(Icons.arrow_outward_rounded, size: 15),
                    label: const Text('Ver historial'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _ImpactPanel(
                donations: _donationCount,
                points: widget.rewardsRepository.pointsBalance,
              ),
              const SizedBox(height: 22),
              _NextDonationCard(onFindCenters: widget.onFindCenters),
              const SizedBox(height: 25),
              _MedicalSummaryCard(
                medicalProfile: widget.medicalProfileRepository.profile,
                onTap: _editMedicalProfile,
              ),
              const SizedBox(height: 20),
              _QuestionnaireCard(
                completed: widget.questionnaireRepository.answers != null,
                onTap: _openQuestionnaire,
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editPersonalInfo() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            PersonalInfoScreen(repository: widget.profileRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editMedicalProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            MedicalProfileScreen(repository: widget.medicalProfileRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQuestionnaire() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HealthQuestionnaireScreen(
          repository: widget.questionnaireRepository,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Volverás a la bienvenida de Bloomi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) widget.onLogout();
  }
}

class _DonorHeader extends StatelessWidget {
  const _DonorHeader({
    required this.name,
    required this.bloodType,
    required this.onEditProfile,
    required this.onLogout,
  });

  final String name;
  final String bloodType;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: _HeaderWaveClipper(),
            child: Container(
              height: 250,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
          ),
          Positioned(
            right: -44,
            top: 64,
            child: Container(
              width: 174,
              height: 174,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .12),
                  width: 22,
                ),
              ),
            ),
          ),
          Positioned(
            right: 43,
            top: 77,
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white.withValues(alpha: .09),
              size: 58,
            ),
          ),
          Positioned(
            top: 20,
            left: 22,
            right: 20,
            child: Row(
              children: [
                const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 23,
                ),
                const SizedBox(width: 7),
                const Text(
                  'bloomi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    letterSpacing: -.6,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEditProfile,
                  tooltip: 'Datos personales y ficha médica',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .16),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.badge_outlined),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: onLogout,
                  tooltip: 'Cerrar sesión',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .16),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          Positioned(
            left: 25,
            top: 91,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softRose, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 56,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 106,
            top: 176,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            left: 158,
            right: 20,
            top: 109,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gracias por ser parte de Bloomi.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bloodtype_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tipo $bloodType',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 34)
      ..cubicTo(
        size.width * .22,
        size.height + 2,
        size.width * .38,
        size.height - 18,
        size.width * .58,
        size.height - 27,
      )
      ..cubicTo(
        size.width * .79,
        size.height - 36,
        size.width * .89,
        size.height - 3,
        size.width,
        size.height - 14,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MedicalSummaryCard extends StatelessWidget {
  const _MedicalSummaryCard({
    required this.medicalProfile,
    required this.onTap,
  });

  final MedicalProfile medicalProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: .12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medical_information_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ficha médica',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primaryDark,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Privada',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.muted,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _summary('Medicamentos', medicalProfile.medications),
              const SizedBox(height: 4),
              _summary('Condiciones', medicalProfile.conditions),
              const SizedBox(height: 4),
              _summary('Alergias', medicalProfile.allergies),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value) {
    final display = value.trim().isEmpty ? 'Sin registrar' : value.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.ink, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.ink,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -.3,
    ),
  );
}

class _ImpactPanel extends StatelessWidget {
  const _ImpactPanel({required this.donations, required this.points});

  final int donations;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.blush],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ImpactMetric(
              icon: Icons.water_drop_rounded,
              value: '$donations',
              label: donations == 1
                  ? 'donación confirmada'
                  : 'donaciones confirmadas',
              iconColor: AppColors.primary,
            ),
          ),
          Container(height: 54, width: 1, color: AppColors.border),
          Expanded(
            child: _ImpactMetric(
              icon: Icons.stars_rounded,
              value: '$points',
              label: 'puntos para tus canjes',
              iconColor: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuestionnaireCard extends StatelessWidget {
  const _QuestionnaireCard({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.softRose, Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuestionario de salud',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed
                        ? 'Tus respuestas están guardadas'
                        : 'Cuéntanos cómo está tu salud',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NextDonationCard extends StatelessWidget {
  const _NextDonationCard({required this.onFindCenters});

  final VoidCallback onFindCenters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu próxima donación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Encuentra un centro y sigue sumando impacto.',
                  style: TextStyle(
                    color: Color(0xFFFFE5E8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 13),
                FilledButton.tonal(
                  onPressed: onFindCenters,
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: Colors.white,
                    minimumSize: const Size(0, 39),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Buscar centros'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}
