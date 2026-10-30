class HealthQuestion {
  const HealthQuestion({
    required this.id,
    required this.category,
    required this.prompt,
    this.required = true,
  });

  final String id;
  final String category;
  final String prompt;
  final bool required;
}
