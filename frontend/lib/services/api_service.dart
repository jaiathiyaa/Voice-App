import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/ai_coach.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  // Helper to generate auth headers
  static Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 🔐 Register
  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  // 🔑 Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Backend expects form-data for OAuth2 login (form_data: OAuth2PasswordRequestForm = Depends())
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/login'));
    request.fields['username'] = email;
    request.fields['password'] = password;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      Map<String, dynamic> error = {};
      try {
        error = jsonDecode(response.body);
      } catch (_) {}
      throw Exception(error['detail'] ?? 'Invalid credentials');
    }
  }

  // 📄 Get All Transactions (Paginated)
  static Future<Map<String, dynamic>> getTransactions(String token, {int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions?page=$page&limit=$limit'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  // ➕ Add Transaction
  static Future<Transaction> addTransaction(String token, Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: _headers(token),
      body: jsonEncode(transaction.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add transaction');
    }
  }

  // ✏️ Update Transaction
  static Future<Transaction> updateTransaction(String token, String id, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers(token),
      body: jsonEncode(updatedData),
    );
    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update transaction');
    }
  }

  // 🗑 Delete Transaction
  static Future<void> deleteTransaction(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction');
    }
  }

  // 🔍 Filter Transactions
  static Future<List<Transaction>> filterTransactions(
    String token, {
    String? category,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (category != null && category.isNotEmpty) params.add('category=$category');
    if (type != null && type.isNotEmpty) params.add('txn_type=$type');
    if (startDate != null && startDate.isNotEmpty) params.add('start_date=$startDate');
    if (endDate != null && endDate.isNotEmpty) params.add('end_date=$endDate');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/filter$queryString'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to filter transactions');
    }
  }

  // 📁 Categories
  static Future<Map<String, dynamic>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // 📊 Transaction Summary
  static Future<Map<String, dynamic>> getSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/summary'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load summary');
    }
  }

  // 🍕 Category Breakdown
  static Future<Map<String, dynamic>> getCategoryBreakdown(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/category-breakdown'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load category breakdown');
    }
  }

  // 💓 Health Score
  static Future<Map<String, dynamic>> getHealthScore(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/health-score'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load health score');
    }
  }

  // 🔔 Alerts
  static Future<List<String>> getAlerts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['alerts'] ?? []);
    } else {
      throw Exception('Failed to load alerts');
    }
  }

  // 🎯 Set Budget
  static Future<void> setBudget(String token, String category, double limit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budget'),
      headers: _headers(token),
      body: jsonEncode({
        'category': category,
        'monthly_limit': limit,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set budget');
    }
  }

  // 📊 Budget Status
  static Future<List<BudgetStatus>> getBudgetStatus(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/budget/status'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((json) => BudgetStatus.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load budget status');
    }
  }

  // 🧠 AI Coach
  static Future<AICoachReport> getAICoachReport(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai-coach'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return AICoachReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load AI Coach report');
    }
  }

  // 🎙️ Voice Transaction Parse
  static Future<Map<String, dynamic>> parseVoiceTransaction(String token, List<int> audioBytes, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/voice-transaction'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to parse audio');
    }
  }

  // 🎙️ Voice Transaction Simulate
  static Future<Map<String, dynamic>> simulateVoiceTransaction(String token, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voice-transaction/simulate'),
      headers: _headers(token),
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to simulate voice transaction');
    }
  }

  // 🎙️ Voice Transaction Confirm
  static Future<void> confirmVoiceTransaction(String token, {
    required double amount,
    required String type,
    required String category,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voice-transaction/confirm'),
      headers: _headers(token),
      body: jsonEncode({
        'amount': amount.toInt(),
        'type': type,
        'category': category,
        'date': date,
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to confirm transaction');
    }
  }

  // ✉️ SMS parse
  static Future<Map<String, dynamic>> parseSMSTransaction(String token, String smsText) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sms-transaction'),
      headers: _headers(token),
      body: jsonEncode({'sms_text': smsText}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to parse SMS');
    }
  }
}
