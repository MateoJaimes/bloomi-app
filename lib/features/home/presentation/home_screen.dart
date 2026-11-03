import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
import '../../../core/widgets/bloomi_design.dart';
import '../../../core/network/api_client.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/medical_profile_repository.dart';
import '../../profile/presentation/medical_profile_screen.dart';
import '../../questionnaire/data/health_questionnaire_repository.dart';
import '../../questionnaire/presentation/health_questionnaire_screen.dart';
import '../../rewards/data/rewards_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.header,
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

  final Widget header;
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

    return BloomiPage(
      header: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: BloomiWave(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Column(
                  children: [
                    widget.header,
                    Row(
                      children: [
                        const SizedBox(width: 110),
                        Expanded(
                          child: Text(
                            'Hola, ${greetingName.isEmpty ? "donante" : greetingName}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softRose, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: .1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    (greetingName.isEmpty ? 'D' : greetingName.characters.first)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: Text(
                      bloodType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 12),
        BloomiMetrics(
          donations: _donationCount,
          points: widget.rewardsRepository.pointsBalance,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onShowImpact,
            child: const Text('Ver mi impacto'),
          ),
        ),
        _NextDonationCard(onFindCenters: widget.onFindCenters),
        const SizedBox(height: 24),
        const Text(
          'Tu salud',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _HealthAction(
          title: 'Ficha médica',
          status: widget.medicalProfileRepository.profile.isCompleted
              ? 'Actualizada'
              : 'Por completar',
          icon: Icons.medical_information_outlined,
          color: AppColors.mint,
          foreground: AppColors.mintInk,
          onTap: _editMedicalProfile,
        ),
        const SizedBox(height: 12),
        _HealthAction(
          title: 'Cuestionario',
          status: widget.questionnaireRepository.answers != null
              ? 'Guardado'
              : 'Pendiente',
          icon: Icons.fact_check_outlined,
          color: AppColors.lavender,
          foreground: AppColors.lavenderInk,
          onTap: _openQuestionnaire,
        ),
      ],
    );
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
}

class _HealthAction extends StatelessWidget {
  const _HealthAction({
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
  });
  final String title, status;
  final IconData icon;
  final Color color, foreground;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BloomiSurface(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        BloomiEmblem(icon, size: 44, background: color, foreground: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
      ],
    ),
  );
}

class _NextDonationCard extends StatelessWidget {
  const _NextDonationCard({required this.onFindCenters});
  final VoidCallback onFindCenters;
  @override
  Widget build(BuildContext context) => BloomiSurface(
    color: AppColors.primary,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu próximo paso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encuentra dónde donar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onFindCenters,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: const Text('Buscar centros'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.bloodtype_outlined, color: Colors.white, size: 60),
      ],
    ),
  );
}
