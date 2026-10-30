import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/rewards_repository.dart';
import '../domain/reward.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({required this.repository, super.key});

  final RewardsRepository repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    return AnimatedBuilder(
      animation: repository is Listenable
          ? repository as Listenable
          : const _NoopListenable(),
      builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 128),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Canjes',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (repository is DemoRewardsRepository) Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Tus puntos se convierten en momentos para ti.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 21),
        _PointsBalanceCard(points: repository.pointsBalance),
        const SizedBox(height: 27),
        const Text(
          'Elige tu recompensa',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (repository is ApiRewardsRepository && repository.error != null)
          Text('No se pudo cargar el catálogo. ${repository.error}', style: const TextStyle(color: AppColors.muted)),
        if (repository.rewards.isEmpty && (repository is! ApiRewardsRepository || repository.error == null))
          const Text('No hay recompensas disponibles por ahora.', style: TextStyle(color: AppColors.muted)),
        for (final reward in repository.rewards) ...[
          _RewardCard(
            reward: reward,
            claimed: repository.isClaimed(reward.id),
            canClaim: repository.canClaim(reward),
            balance: repository.pointsBalance,
            onClaim: () => _claim(reward),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 5),
        Text(
          repository is DemoRewardsRepository ? 'Catálogo de demostración.' : 'Cada canje se confirma y descuenta directamente en tu cuenta Bloomi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.45),
        ),
      ],
      ),
    );
  }

  Future<void> _claim(Reward reward) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Text(
          '¿Quieres usar ${reward.pointsCost} puntos para reclamar “${reward.title}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, canjear'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    bool success;
    try {
      success = await widget.repository.claim(reward);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo realizar el canje. $error')));
      return;
    }
    if (!success) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Canje realizado! ${reward.title}')),
    );
  }
}

class _NoopListenable implements Listenable {
  const _NoopListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tienes disponibles',
                  style: TextStyle(color: Color(0xFFFFE5E8), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  '$points puntos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.card_giftcard_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.claimed,
    required this.canClaim,
    required this.balance,
    required this.onClaim,
  });

  final Reward reward;
  final bool claimed;
  final bool canClaim;
  final int balance;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final pointsNeeded = reward.pointsCost - balance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    _iconFor(reward.iconKey),
                    color: AppColors.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.stars_rounded, size: 17, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  '${reward.pointsCost} pts',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (claimed)
                  const Text(
                    'Reclamado',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (!canClaim)
                  Text(
                    'Te faltan $pointsNeeded pts',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onClaim,
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      backgroundColor: AppColors.blush,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Canjear'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'drinkware' => Icons.water_drop_outlined,
    'coffee' => Icons.coffee_rounded,
    _ => Icons.spa_outlined,
  };
}
