import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
import '../../../core/widgets/bloomi_design.dart';
import '../data/rewards_repository.dart';
import '../domain/reward.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({required this.repository, super.key});
  final RewardsRepository repository;
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _claiming = false;
  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    return AnimatedBuilder(
      animation: repository is Listenable
          ? repository as Listenable
          : const _NoopListenable(),
      builder: (context, _) => BloomiPage(
        children: [
          const BloomiTitle('Canjes', 'Pequeños detalles por tu gran gesto.'),
          const SizedBox(height: 24),
          BloomiSurface(
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu saldo',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${repository.pointsBalance} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const BloomiIcon(
                  'material-symbols:redeem-rounded',
                  size: 40,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Catálogo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (repository is ApiRewardsRepository && repository.error != null)
            BloomiSurface(
              child: Column(
                children: [
                  const Text(
                    'No pudimos actualizar el catálogo. Intenta de nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await repository.load();
                      } catch (_) {}
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (repository.rewards.isEmpty)
            const BloomiNotice(
              title: 'Nuevos beneficios en camino',
              detail: 'Aún no hay recompensas disponibles. Tus puntos seguirán aquí para tu próximo canje.',
              icon: 'redeem-outline-rounded',
            ),
          for (final reward in repository.rewards) ...[
            _RewardCard(
              reward: reward,
              claimed: repository.isClaimed(reward.id),
              canClaim: repository.canClaim(reward),
              balance: repository.pointsBalance,
              busy: _claiming,
              onClaim: () => _claim(reward),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text(
            repository is DemoRewardsRepository
                ? 'Catálogo de demostración.'
                : 'Cada canje se confirma y descuenta de tu cuenta Bloomi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(Reward reward) async {
    if (_claiming) return;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: BloomiEmblem(
                  Icons.card_giftcard_outlined,
                  size: 72,
                  background: AppColors.blush,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Confirmar canje',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              BloomiSurface(
                child: Column(
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BloomiPill('${reward.pointsCost} puntos'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BloomiSurface(
                color: AppColors.blush,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Saldo después del canje: ${widget.repository.pointsBalance - reward.pointsCost} puntos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, canjear'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted != true || !mounted || _claiming) return;
    setState(() => _claiming = true);
    try {
      final success = await widget.repository.claim(reward);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '¡Canje realizado! ${reward.title}'
                : 'Este canje ya no está disponible. Revisa tu saldo.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos confirmar el canje. Revisa tu saldo antes de intentarlo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }
}

class _NoopListenable implements Listenable {
  const _NoopListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.claimed,
    required this.canClaim,
    required this.balance,
    required this.busy,
    required this.onClaim,
  });
  final Reward reward;
  final bool claimed;
  final bool canClaim;
  final int balance;
  final bool busy;
  final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) => BloomiSurface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BloomiEmblem(
          claimed
              ? Icons.check_circle_outline
              : switch (reward.iconKey) {
                  'coffee' => Icons.coffee_outlined,
                  'drinkware' => Icons.water_drop_outlined,
                  _ => Icons.card_giftcard_outlined,
                },
          size: 60,
          background: switch (reward.iconKey) {
            'coffee' => AppColors.butter,
            'drinkware' => AppColors.mint,
            _ => AppColors.lavender,
          },
          foreground: switch (reward.iconKey) {
            'coffee' => AppColors.butterInk,
            'drinkware' => AppColors.mintInk,
            _ => AppColors.lavenderInk,
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reward.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reward.description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${reward.pointsCost} pts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (claimed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BloomiIcon(
                            'material-symbols:check-rounded',
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Canjeado',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!canClaim)
                    Text(
                      'Faltan ${reward.pointsCost - balance} pts',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: busy ? null : onClaim,
                      child: Text(busy ? 'Confirmando…' : 'Canjear'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
