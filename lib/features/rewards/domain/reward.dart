class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconKey;
}
