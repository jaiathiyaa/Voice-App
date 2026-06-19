import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/ai_coach.dart';
import '../services/api_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;
  int _healthScore = 0;
  double _savingsRatio = 0.0;
  List<BudgetStatus> _budgets = [];
  List<String> _alerts = [];
  AICoachReport? _coachReport;

  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  bool _isLoading = false;
  bool _isVoiceParsing = false;
  bool _isSMSParsing = false;
  
  Map<String, dynamic>? _parsedVoiceData;
  String? _spokenText;
  Map<String, dynamic>? _parsedSMSData;

  // Getters
  List<Transaction> get transactions => _transactions;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  int get healthScore => _healthScore;
  double get savingsRatio => _savingsRatio;
  List<BudgetStatus> get budgets => _budgets;
  List<String> get alerts => _alerts;
  AICoachReport? get coachReport => _coachReport;
  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;

  bool get isLoading => _isLoading;
  bool get isVoiceParsing => _isVoiceParsing;
  bool get isSMSParsing => _isSMSParsing;

  Map<String, dynamic>? get parsedVoiceData => _parsedVoiceData;
  String? get spokenText => _spokenText;
  Map<String, dynamic>? get parsedSMSData => _parsedSMSData;

  // 🚀 Fetch All Initial Data
  Future<void> fetchAllData(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadCategories(token),
        _loadSummary(token),
        _loadHealthScore(token),
        _loadTransactions(token),
        _loadBudgets(token),
        _loadAlerts(token),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard(String token) async {
    await Future.wait([
      _loadSummary(token),
      _loadHealthScore(token),
      _loadTransactions(token),
      _loadBudgets(token),
      _loadAlerts(token),
    ]);
    notifyListeners();
  }

  Future<void> _loadCategories(String token) async {
    final catData = await ApiService.getCategories(token);
    _incomeCategories = List<String>.from(catData['income_categories'] ?? []);
    _expenseCategories = List<String>.from(catData['expense_categories'] ?? []);
  }

  Future<void> _loadSummary(String token) async {
    final sum = await ApiService.getSummary(token);
    _totalIncome = (sum['total_income'] as num?)?.toDouble() ?? 0.0;
    _totalExpense = (sum['total_expense'] as num?)?.toDouble() ?? 0.0;
    _balance = (sum['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _loadHealthScore(String token) async {
    final health = await ApiService.getHealthScore(token);
    _healthScore = health['health_score'] as int? ?? 0;
    _savingsRatio = (health['savings_ratio'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _loadTransactions(String token) async {
    final res = await ApiService.getTransactions(token);
    final List dataList = res['data'] ?? [];
    _transactions = dataList.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> _loadBudgets(String token) async {
    _budgets = await ApiService.getBudgetStatus(token);
  }

  Future<void> _loadAlerts(String token) async {
    _alerts = await ApiService.getAlerts(token);
  }

  // ➕ Add Transaction
  Future<bool> addTransaction(String token, Transaction txn) async {
    try {
      await ApiService.addTransaction(token, txn);
      await refreshDashboard(token);
      return true;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  // ✏️ Update Transaction
  Future<bool> updateTransaction(String token, String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateTransaction(token, id, data);
      await refreshDashboard(token);
      return true;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  // 🗑 Delete Transaction
  Future<bool> deleteTransaction(String token, String id) async {
    try {
      await ApiService.deleteTransaction(token, id);
      await refreshDashboard(token);
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // 🔍 Filter Transactions
  Future<void> filterTransactions(
    String token, {
    String? category,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await ApiService.filterTransactions(
        token,
        category: category,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error filtering transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🎯 Set Budget
  Future<bool> setBudget(String token, String category, double limit) async {
    try {
      await ApiService.setBudget(token, category, limit);
      await _loadBudgets(token);
      await _loadAlerts(token);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error setting budget: $e');
      return false;
    }
  }

  // 🧠 Load AI Coach Report
  Future<void> fetchAICoachReport(String token) async {
    _isLoading = true;
    _coachReport = null;
    notifyListeners();

    try {
      _coachReport = await ApiService.getAICoachReport(token);
    } catch (e) {
      print('Error loading AI coach: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🎙️ Parse Voice Transaction
  Future<bool> parseVoice(String token, List<int> audioBytes, String filename) async {
    _isVoiceParsing = true;
    _parsedVoiceData = null;
    _spokenText = null;
    notifyListeners();

    try {
      final res = await ApiService.parseVoiceTransaction(token, audioBytes, filename);
      _parsedVoiceData = res['parsed_data'];
      _spokenText = res['spoken_text'];
      _isVoiceParsing = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error parsing voice: $e');
      _isVoiceParsing = false;
      notifyListeners();
      return false;
    }
  }

  // 🎙️ Simulate Voice Transaction
  Future<bool> simulateVoice(String token, String text) async {
    _isVoiceParsing = true;
    _parsedVoiceData = null;
    _spokenText = null;
    notifyListeners();

    try {
      final res = await ApiService.simulateVoiceTransaction(token, text);
      _parsedVoiceData = res['parsed_data'];
      _spokenText = res['spoken_text'];
      _isVoiceParsing = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error simulating voice: $e');
      _isVoiceParsing = false;
      notifyListeners();
      return false;
    }
  }

  // 🎙️ Confirm Voice Transaction
  Future<bool> confirmVoice(String token, double amount, String type, String category, String date) async {
    try {
      await ApiService.confirmVoiceTransaction(
        token,
        amount: amount,
        type: type,
        category: category,
        date: date,
      );
      _parsedVoiceData = null;
      _spokenText = null;
      await refreshDashboard(token);
      return true;
    } catch (e) {
      print('Error confirming voice: $e');
      return false;
    }
  }

  void clearVoice() {
    _parsedVoiceData = null;
    _spokenText = null;
    notifyListeners();
  }

  // ✉️ Parse SMS Transaction
  Future<bool> parseSMS(String token, String smsText) async {
    _isSMSParsing = true;
    _parsedSMSData = null;
    notifyListeners();

    try {
      final res = await ApiService.parseSMSTransaction(token, smsText);
      _parsedSMSData = res['parsed_data'];
      _isSMSParsing = false;
      await refreshDashboard(token);
      return true;
    } catch (e) {
      print('Error parsing SMS: $e');
      _isSMSParsing = false;
      notifyListeners();
      return false;
    }
  }

  void clearSMS() {
    _parsedSMSData = null;
    notifyListeners();
  }
}
