import '../domain/reward.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';

abstract interface class RewardsRepository {
  int get pointsBalance;
  List<Reward> get rewards;
  bool isClaimed(String rewardId);
  bool canClaim(Reward reward);
  Future<bool> claim(Reward reward);
}

/// Sample in-memory balance and catalogue for the UI prototype only.
class DemoRewardsRepository implements RewardsRepository {
  int _balance = 650;
  final Set<String> _claimedRewardIds = {};

  static const _catalogue = [
    Reward(
      id: 'drinkware',
      title: 'Botella reutilizable',
      description: 'Un detalle para acompañarte cada día.',
      pointsCost: 250,
      iconKey: 'drinkware',
    ),
    Reward(
      id: 'coffee',
      title: 'Café para compartir',
      description: 'Disfruta una pausa en un lugar aliado.',
      pointsCost: 400,
      iconKey: 'coffee',
    ),
    Reward(
      id: 'wellness',
      title: 'Experiencia de bienestar',
      description: 'Un momento para cuidar también de ti.',
      pointsCost: 600,
      iconKey: 'wellness',
    ),
  ];

  @override
  int get pointsBalance => _balance;

  @override
  List<Reward> get rewards => _catalogue;

  @override
  bool isClaimed(String rewardId) => _claimedRewardIds.contains(rewardId);

  @override
  bool canClaim(Reward reward) =>
      !isClaimed(reward.id) && _balance >= reward.pointsCost;

  @override
  Future<bool> claim(Reward reward) async {
    if (!canClaim(reward)) return false;
    _balance -= reward.pointsCost;
    _claimedRewardIds.add(reward.id);
    return true;
  }
}

class ApiRewardsRepository extends ChangeNotifier implements RewardsRepository {
  ApiRewardsRepository(this.api);
  final ApiClient api;
  int _balance = 0;
  String? error;
  List<Reward> _rewards = [];
  final Set<String> _claimed = {};
  @override
  int get pointsBalance => _balance;
  @override
  List<Reward> get rewards => List.unmodifiable(_rewards);
  @override
  bool isClaimed(String rewardId) => _claimed.contains(rewardId);
  @override
  bool canClaim(Reward reward) => !isClaimed(reward.id) && _balance >= reward.pointsCost;

  Future<void> load() async {
    error = null;
    try {
      final responses = await Future.wait([api.get('/rewards'), api.get('/me/points'), api.get('/me/redemptions')]);
    _rewards = (responses[0] as List).map((row) {
      final item = row as Map<String, dynamic>;
      return Reward(id: item['id'].toString(), title: item['name'] as String? ?? 'Recompensa', description: item['description'] as String? ?? '', pointsCost: (item['points_cost'] as num?)?.toInt() ?? 0, iconKey: _iconFor(item['name']?.toString() ?? ''));
    }).toList();
    final points = responses[1] as Map<String, dynamic>;
    _balance = parseApiInt(points['balance']) ?? 0;
    _claimed
      ..clear()
      ..addAll((responses[2] as List).map((r) => (r as Map<String, dynamic>)['reward_id'].toString()));
    notifyListeners();
    } catch (exception) {
      error = exception.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<bool> claim(Reward reward) async {
    if (!canClaim(reward)) return false;
    await api.post('/me/redemptions', body: {'rewardId': reward.id});
    await load();
    return true;
  }

  String _iconFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('agua') || value.contains('botella')) return 'drinkware';
    if (value.contains('café')) return 'coffee';
    return 'wellness';
  }
}
