class AICoachReport {
  final double income;
  final double expense;
  final double savings;
  final int healthScore;
  final String riskLevel;
  final List<String> topIssues;
  final List<String> actionSteps;
  final String longTermStrategy;
  final String motivation;

  AICoachReport({
    required this.income,
    required this.expense,
    required this.savings,
    required this.healthScore,
    required this.riskLevel,
    required this.topIssues,
    required this.actionSteps,
    required this.longTermStrategy,
    required this.motivation,
  });

  factory AICoachReport.fromJson(Map<String, dynamic> json) {
    final analysis = json['ai_analysis'] as Map<String, dynamic>? ?? {};
    return AICoachReport(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      healthScore: json['health_score'] as int? ?? 0,
      riskLevel: analysis['risk_level'] ?? 'Low',
      topIssues: List<String>.from(analysis['top_issues'] ?? []),
      actionSteps: List<String>.from(analysis['action_steps'] ?? []),
      longTermStrategy: analysis['long_term_strategy'] ?? '',
      motivation: analysis['motivation'] ?? '',
    );
  }
}
