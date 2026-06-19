import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  String _selectedType = 'All'; // 'All', 'income', 'expense'
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      Provider.of<FinanceProvider>(context, listen: false).refreshDashboard(token);
    }
  }

  void _applyFilters() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    financeProvider.filterTransactions(
      token,
      type: _selectedType == 'All' ? null : _selectedType,
      category: _selectedCategory,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedCategory = null;
    });
    _applyFilters();
  }

  void _showAddEditTransactionDialog({Transaction? transaction}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditTransactionDialog(
          transaction: transaction,
          onSaved: () {
            _loadData();
          },
        );
      },
    );
  }

  void _deleteTransaction(String id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C33),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6366F1))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<FinanceProvider>(context, listen: false)
          .deleteTransaction(token, id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final transactions = financeProvider.transactions;
    final categories = _selectedType == 'income'
        ? financeProvider.incomeCategories
        : _selectedType == 'expense'
            ? financeProvider.expenseCategories
            : [...financeProvider.incomeCategories, ...financeProvider.expenseCategories];

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditTransactionDialog(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_selectedType != 'All' || _selectedCategory != null)
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all, color: Color(0xFF6366F1), size: 18),
                    label: const Text(
                      'Clear Filters',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type Filter Buttons
                  _buildFilterChip('All', _selectedType == 'All', (val) {
                    setState(() => _selectedType = 'All');
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Income', _selectedType == 'income', (val) {
                    setState(() {
                      _selectedType = 'income';
                      _selectedCategory = null; // Reset category filter if type changes
                    });
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expenses', _selectedType == 'expense', (val) {
                    setState(() {
                      _selectedType = 'expense';
                      _selectedCategory = null;
                    });
                    _applyFilters();
                  }),
                  const VerticalDivider(color: Colors.white24, width: 20),

                  // Category Dropdown Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF131C33),
                        value: _selectedCategory,
                        hint: const Text(
                          'Category',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.toSet().map((cat) => DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              )),
                        ],
                        onChanged: (cat) {
                          setState(() => _selectedCategory = cat);
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transaction List
            Expanded(
              child: financeProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  color: Colors.white.withOpacity(0.2), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found matching criteria',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isIncome = tx.type == 'income';
                            return Card(
                              color: const Color(0xFF131C33),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? const Color(0xFF10B981).withOpacity(0.1)
                                        : Colors.redAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  tx.description.isNotEmpty ? tx.description : tx.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.category,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy • h:mm a').format(tx.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                                      color: const Color(0xFF1E293B),
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showAddEditTransactionDialog(transaction: tx);
                                        } else if (action == 'delete') {
                                          _deleteTransaction(tx.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF6366F1),
      disabledColor: const Color(0xFF131C33),
      backgroundColor: const Color(0xFF131C33),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
        ),
      ),
    );
  }
}

class AddEditTransactionDialog extends StatefulWidget {
  final Transaction? transaction;
  final VoidCallback onSaved;

  const AddEditTransactionDialog({super.key, this.transaction, required this.onSaved});

  @override
  State<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  String? _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    bool success;
    if (widget.transaction == null) {
      final newTx = Transaction(
        id: '',
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category!,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );
      success = await provider.addTransaction(token, newTx);
    } else {
      final updatedData = {
        'amount': double.parse(_amountController.text),
        'type': _type,
        'category': _category!,
        'description': _descriptionController.text.trim(),
      };
      success = await provider.updateTransaction(token, widget.transaction!.id, updatedData);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction == null ? 'Transaction added successfully' : 'Transaction updated successfully',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save transaction'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final categories = _type == 'income'
        ? financeProvider.incomeCategories
        : financeProvider.expenseCategories;

    // Ensure selected category is valid for type
    if (_category != null && !categories.contains(_category)) {
      _category = null;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF131C33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Text(
        widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _type == 'expense',
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = 'expense';
                            _category = null;
                          });
                        }
                      },
                      selectedColor: Colors.redAccent,
                      disabledColor: const Color(0xFF0F172A),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: _type == 'expense' ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: _type == 'income',
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = 'income';
                            _category = null;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF10B981),
                      disabledColor: const Color(0xFF0F172A),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: _type == 'income' ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
                  if (val == null || val.isEmpty) return 'Please enter amount';
                  if (double.tryParse(val) == null) return 'Please enter a valid number';
                  if (double.parse(val) <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    value: _category,
                    hint: const Text(
                      'Select Category',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: categories.map((cat) => DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                    onChanged: (cat) {
                      setState(() => _category = cat);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
