import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  final _limitController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  bool _isSaving = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category and enter a valid limit'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    final limit = double.parse(_limitController.text);

    final success = await Provider.of<FinanceProvider>(context, listen: false)
        .setBudget(token, _selectedCategory!, limit);

    setState(() => _isSaving = false);

    if (success && mounted) {
      _limitController.clear();
      setState(() => _selectedCategory = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget configured successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to set budget'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final budgets = financeProvider.budgets;
    final categories = financeProvider.expenseCategories;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Budgets & Limits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control your monthly expenses by configuring target category budget allowances',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Set Budget Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C33),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.track_changes_outlined, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Configure Category Limit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 600;
                          final fieldWidget = [
                            // Dropdown
                            Expanded(
                              flex: isDesktop ? 2 : 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: const Color(0xFF0F172A),
                                    value: _selectedCategory,
                                    hint: const Text(
                                      'Select Expense Category',
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    items: categories.map((cat) => DropdownMenuItem<String>(
                                          value: cat,
                                          child: Text(cat),
                                        )).toList(),
                                    onChanged: (cat) {
                                      setState(() => _selectedCategory = cat);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
                            // Limit Input
                            Expanded(
                              flex: isDesktop ? 2 : 0,
                              child: TextFormField(
                                controller: _limitController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Monthly Allowance (₹)',
                                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Enter budget limit';
                                  if (double.tryParse(val) == null) return 'Invalid limit number';
                                  if (double.parse(val) <= 0) return 'Limit must be greater than 0';
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 20),
                            // Save Button
                            SizedBox(
                              width: isDesktop ? null : double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveBudget,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Set Allowance',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ];

                          return isDesktop
                              ? Row(children: fieldWidget)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    fieldWidget[0], // Dropdown
                                    fieldWidget[1], // Spacer
                                    fieldWidget[2], // Limit Input
                                    fieldWidget[3], // Spacer
                                    fieldWidget[4], // Button
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Active Limits List
              const Text(
                'Active Budget Allowance Limits',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (budgets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C33),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline, color: Colors.white.withOpacity(0.2), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No allowances configured yet. Use the form above to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final ratio = budget.limit > 0 ? (budget.spent / budget.limit) : 0.0;
                    final isExceeded = budget.status.toLowerCase() == 'exceeded';
                    final color = isExceeded ? Colors.redAccent : const Color(0xFF10B981);

                    return Card(
                      color: const Color(0xFF131C33),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  budget.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    budget.status,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${budget.spent.toStringAsFixed(0)} spent',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'of ₹${budget.limit.toStringAsFixed(0)} allowance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio > 1.0 ? 1.0 : ratio,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isExceeded
                                      ? 'Overspent by ₹${(budget.spent - budget.limit).toStringAsFixed(0)}'
                                      : '₹${budget.remaining.toStringAsFixed(0)} remaining allowance',
                                  style: TextStyle(
                                    color: isExceeded ? Colors.redAccent : Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${(ratio * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                )
            ],
          ),
        ),
      ),
    );
  }
}
