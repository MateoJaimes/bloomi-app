import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_florist_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'bloomi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _WelcomeHero(onRegister: onRegister),
            const SizedBox(height: 28),
            const Text(
              'Donar, paso a paso',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _HowItWorksCard(
              number: '01',
              icon: Icons.person_add_alt_1_rounded,
              title: 'Crea tu perfil',
              detail: 'Cuéntanos quién eres y registra tus datos de donante.',
            ),
            const SizedBox(height: 10),
            const _HowItWorksCard(
              number: '02',
              icon: Icons.location_on_outlined,
              title: 'Encuentra un centro',
              detail:
                  'Explora instituciones y opciones para donar cerca de ti.',
            ),
            const SizedBox(height: 10),
            const _HowItWorksCard(
              number: '03',
              icon: Icons.card_giftcard_rounded,
              title: 'Sigue tu impacto',
              detail:
                  'Consulta donaciones, puntos y recompensas desde tu cuenta.',
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onLogin,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Ya tengo una cuenta · Iniciar sesión'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Al crear tu cuenta podrás acceder a tu perfil y seguimiento personal. Los datos reales se activarán cuando Bloomi conecte su servicio seguro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'UNA COMUNIDAD QUE SALVA VIDAS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu próxima\ndonación puede\nmarcar la diferencia.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Conecta con centros de donación y lleva el registro de tu camino como donante.',
            style: TextStyle(
              color: Color(0xFFFFE5E8),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text('Registrarme'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final String number;
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 13),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
