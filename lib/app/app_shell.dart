import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/centers/presentation/centers_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/impact/presentation/impact_screen.dart';
import '../features/home/presentation/public_landing_screen.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/medical_profile_repository.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/questionnaire/data/health_questionnaire_repository.dart';
import '../features/rewards/data/rewards_repository.dart';
import '../features/rewards/presentation/rewards_screen.dart';
import '../core/network/api_client.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final ApiClient _api = ApiClient();
  late ApiProfileRepository _profileRepository;
  late ApiMedicalProfileRepository _medicalProfileRepository;
  late ApiHealthQuestionnaireRepository _questionnaireRepository;
  late ApiRewardsRepository _rewardsRepository;
  bool _isAuthenticated = false;
  bool _isRestoring = true;
  bool _requiresProfileCompletion = false;

  @override
  void initState() {
    super.initState();
    _createRepositories();
    _restoreSession();
  }

  void _createRepositories() {
    _profileRepository = ApiProfileRepository(_api);
    _medicalProfileRepository = ApiMedicalProfileRepository(_api);
    _questionnaireRepository = ApiHealthQuestionnaireRepository(_api);
    _rewardsRepository = ApiRewardsRepository(_api);
  }

  Future<void> _restoreSession() async {
    try {
      await _api.restoreSession();
      if (_api.hasSession) {
        await _loadUserData();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 400 || error.statusCode == 401) {
        await _api.clearSession();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isAuthenticated = _api.hasSession;
        _requiresProfileCompletion = _api.hasSession && !_hasCompleteProfile;
        _isRestoring = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _profileRepository.load().catchError((_) {}),
      _medicalProfileRepository.load().catchError((_) {}),
      _questionnaireRepository.load().catchError((_) {}),
      _rewardsRepository.load().catchError((_) {}),
    ]);
  }

  List<Widget> get _screens => [
    HomeScreen(
      onFindCenters: () => _selectTab(1),
      onShowImpact: () => _selectTab(3),
      onLogout: _logout,
      api: _api,
      profileRepository: _profileRepository,
      medicalProfileRepository: _medicalProfileRepository,
      questionnaireRepository: _questionnaireRepository,
      rewardsRepository: _rewardsRepository,
    ),
    CentersScreen(api: _api),
    RewardsScreen(repository: _rewardsRepository),
    ImpactScreen(api: _api),
  ];

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAuthenticated) {
      return PublicLandingScreen(
        onLogin: () => _openAuth(initiallyRegistering: false),
        onRegister: () => _openAuth(initiallyRegistering: true),
      );
    }

    if (_requiresProfileCompletion) {
      return ProfileSetupScreen(
        profileRepository: _profileRepository,
        medicalProfileRepository: _medicalProfileRepository,
        isRequiredFlow: true,
        onRequiredComplete: () {
          if (mounted) setState(() => _requiresProfileCompletion = false);
        },
      );
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: _FloatingNavigationBar(
          selectedIndex: _selectedIndex,
          onSelected: _selectTab,
        ),
      ),
    );
  }

  Future<void> _openAuth({required bool initiallyRegistering}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          initiallyRegistering: initiallyRegistering,
          onAuthenticated: _handleAuthentication,
        ),
      ),
    );
  }

  Future<void> _handleAuthentication(
    BuildContext authContext,
    bool isRegistering,
    String email,
    String password,
    String document,
    String documentType,
  ) async {
    if (isRegistering) {
      await _api.register(
        email: email,
        password: password,
        documentNumber: document,
        documentType: documentType,
      );
    } else {
      await _api.login(email: email, password: password);
    }
    if (!authContext.mounted) return;
    if (!_api.hasSession) {
      ScaffoldMessenger.of(authContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un correo para confirmar tu cuenta. Después inicia sesión.',
          ),
        ),
      );
      return;
    }
    await _loadUserData();
    if (!mounted || !authContext.mounted) return;
    setState(() {
      _isAuthenticated = true;
      _requiresProfileCompletion = !_hasCompleteProfile;
    });
    Navigator.pop(authContext);
  }

  bool get _hasCompleteProfile {
    final profile = _profileRepository.profile;
    final medical = _medicalProfileRepository.profile;
    return profile != null &&
        profile.firstName.trim().isNotEmpty &&
        profile.secondName.trim().isNotEmpty &&
        profile.lastName.trim().isNotEmpty &&
        profile.secondLastName.trim().isNotEmpty &&
        profile.birthDate != null &&
        profile.gender.trim().isNotEmpty &&
        profile.department.trim().isNotEmpty &&
        profile.city.trim().isNotEmpty &&
        medical.isCompleted;
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } catch (_) {
      await _api.clearSession();
    }
    _rewardsRepository.dispose();
    _createRepositories();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _selectedIndex = 0;
    });
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.location_on_rounded, label: 'Centros'),
    (icon: Icons.card_giftcard_rounded, label: 'Canjes'),
    (icon: Icons.favorite_rounded, label: 'Impacto'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .22),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .96),
                  AppColors.blush.withValues(alpha: .92),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .2),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      icon: _items[index].icon,
                      label: _items[index].label,
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: selected
                        ? Border.all(color: Colors.white.withValues(alpha: .32))
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .4),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected ? Colors.white : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
