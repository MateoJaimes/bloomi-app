import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/bloomi_ui.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/centers/presentation/centers_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/impact/presentation/impact_screen.dart';
import '../features/home/presentation/public_landing_screen.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/medical_profile_repository.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/presentation/personal_info_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/questionnaire/data/health_questionnaire_repository.dart';
import '../features/rewards/data/rewards_repository.dart';
import '../features/rewards/presentation/rewards_screen.dart';
import '../core/network/api_client.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.api, super.key});

  final ApiClient? api;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _navigationCollapsed = false;
  late final ApiClient _api = widget.api ?? ApiClient();
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
      header: Padding(
        key: const ValueKey('home-header'),
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            IconButton(
              onPressed: _openPersonalInfo,
              tooltip: 'Datos personales',
              icon: const BloomiIcon(
                'material-symbols:person-outline-rounded',
                color: Colors.white,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Bloomi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _confirmLogout,
              tooltip: 'Cerrar sesión',
              icon: const BloomiIcon(
                'material-symbols:logout-rounded',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      onFindCenters: () => _selectTab(1),
      onShowImpact: () => _selectTab(4),
      onLogout: _logout,
      api: _api,
      profileRepository: _profileRepository,
      medicalProfileRepository: _medicalProfileRepository,
      questionnaireRepository: _questionnaireRepository,
      rewardsRepository: _rewardsRepository,
    ),
    CentersScreen(api: _api),
    ChatScreen(
      onFindCenters: () => _selectTab(1),
      onShowRewards: () => _selectTab(3),
    ),
    RewardsScreen(repository: _rewardsRepository),
    ImpactScreen(api: _api),
  ];

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _navigationCollapsed = false;
    });
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: _handleUserScroll,
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FloatingNavigationBar(
                selectedIndex: _selectedIndex,
                collapsed: _navigationCollapsed,
                onSelected: _selectTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.direction == ScrollDirection.idle) {
      return false;
    }
    final collapsed = notification.direction == ScrollDirection.reverse;
    if (_navigationCollapsed != collapsed) {
      setState(() => _navigationCollapsed = collapsed);
    }
    return false;
  }

  Future<void> _openPersonalInfo() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInfoScreen(repository: _profileRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true && mounted) await _logout();
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
    required this.collapsed,
    required this.onSelected,
  });
  final int selectedIndex;
  final bool collapsed;
  final ValueChanged<int> onSelected;
  static const _items = [
    (icon: 'home', label: 'Inicio'),
    (icon: 'location-on', label: 'Centros'),
    (icon: 'chat', label: 'Chatbot'),
    (icon: 'redeem', label: 'Canjes'),
    (icon: 'favorite', label: 'Impacto'),
  ];
  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final inset = MediaQuery.paddingOf(context).bottom;
    final margin = collapsed ? 28.0 : 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AnimatedContainer(
          key: const ValueKey('floating-navigation'),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          height: collapsed ? 52 : 68,
          margin: EdgeInsets.fromLTRB(margin, 0, margin, inset + margin),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.border.withValues(alpha: .8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: ColoredBox(
                color: AppColors.surface.withValues(alpha: .78),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavigationDestination(
                          selected: i == selectedIndex,
                          icon: _items[i].icon,
                          label: _items[i].label,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool selected;
  final String icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.blush : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TweenAnimationBuilder<Color?>(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(
                      end: selected ? AppColors.primaryDark : AppColors.muted,
                    ),
                    builder: (context, color, _) => icon == 'chat'
                        ? Icon(
                            selected
                                ? Icons.smart_toy_rounded
                                : Icons.smart_toy_outlined,
                            color: color,
                            size: 24,
                          )
                        : BloomiIcon(
                            'material-symbols:$icon${selected ? "" : "-outline"}-rounded',
                            color: color,
                          ),
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
