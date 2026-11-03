import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_design.dart';

class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });
  final VoidCallback onLogin, onRegister;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 36),
            children: [
              BloomiWave(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 36),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/brand/bloomi-logo.png',
                        width: 92,
                        height: 92,
                        color: Colors.white,
                      ),
                      const Text(
                        'Bloomi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Icon(
                        Icons.volunteer_activism_outlined,
                        size: 108,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tu donación puede cambiar una historia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Conecta con centros y acompaña tu camino como donante.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: onRegister,
                      child: const Text('Registrarme'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onLogin,
                      child: const Text('Ya tengo una cuenta'),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Una comunidad que acompaña tu donación',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
