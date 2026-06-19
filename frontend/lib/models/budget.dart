class BudgetStatus {
  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final String status; // 'Safe' or 'Exceeded'

  BudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.status,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      category: json['category'] ?? '',
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Safe',
    );
  }
}
