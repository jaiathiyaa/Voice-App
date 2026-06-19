import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';

class AICoachView extends StatefulWidget {
  const AICoachView({super.key});

  @override
  State<AICoachView> createState() => _AICoachViewState();
}

class _AICoachViewState extends State<AICoachView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<FinanceProvider>(context, listen: false).fetchAICoachReport(token);
      }
    });
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final report = financeProvider.coachReport;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Financial Coach',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized advisor recommendations powered by AI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    final token = authProvider.token;
                    if (token != null) {
                      financeProvider.fetchAICoachReport(token);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: financeProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : report == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.psychology_outlined, color: Colors.white.withOpacity(0.2), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No analysis available. Please check back later.',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Risk & Stats Cards
                              _buildOverviewSection(report),
                              const SizedBox(height: 24),

                              // Top Issues
                              _buildListCard(
                                title: 'Key Financial Issues',
                                items: report.topIssues,
                                icon: Icons.error_outline_rounded,
                                iconColor: Colors.redAccent,
                              ),
                              const SizedBox(height: 24),

                              // Action Steps
                              _buildListCard(
                                title: 'Recommended Actions',
                                items: report.actionSteps,
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 24),

                              // Long term strategy
                              _buildTextCard(
                                title: 'Long-term Financial Strategy',
                                content: report.longTermStrategy,
                                icon: Icons.map_outlined,
                                iconColor: const Color(0xFF6366F1),
                              ),
                              const SizedBox(height: 24),

                              // Motivation Quote
                              _buildMotivationQuote(report.motivation),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(dynamic report) {
    final riskColor = _getRiskColor(report.riskLevel);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;
        final content = [
          // Risk Indicator
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF131C33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('RISK LEVEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    report.riskLevel.toUpperCase(),
                    style: TextStyle(color: riskColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.shield_outlined, color: riskColor, size: 36),
                ],
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
          // Health score
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF131C33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('HEALTH SCORE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    '${report.healthScore}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Savings Ratio: ${(report.savings * 100 / (report.income > 0 ? report.income : 1)).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
          // Overview Stats
          Expanded(
            flex: isDesktop ? 2 : 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF131C33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildStatRow('Total Income', '₹${report.income.toStringAsFixed(0)}', const Color(0xFF10B981)),
                  const Divider(color: Colors.white12, height: 16),
                  _buildStatRow('Total Expenses', '₹${report.expense.toStringAsFixed(0)}', Colors.redAccent),
                  const Divider(color: Colors.white12, height: 16),
                  _buildStatRow('Net Savings', '₹${report.savings.toStringAsFixed(0)}', const Color(0xFF6366F1)),
                ],
              ),
            ),
          ),
        ];

        return isDesktop
            ? Row(children: content)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content[0], // Risk
                  content[1], // Spacer
                  content[2], // Health score
                  content[3], // Spacer
                  content[4], // Stats
                ],
              );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131C33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No items detected.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right_rounded, color: iconColor, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTextCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131C33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content.isNotEmpty ? content : 'No strategy data available.',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationQuote(String motivationText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1).withOpacity(0.08), const Color(0xFF4F46E5).withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Color(0xFF6366F1), size: 32),
          const SizedBox(height: 8),
          Text(
            motivationText.isNotEmpty ? motivationText : "Your financial journey requires consistency. Step by step, you will achieve independence.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
