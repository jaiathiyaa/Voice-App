import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';

class SMSSandboxView extends StatefulWidget {
  const SMSSandboxView({super.key});

  @override
  State<SMSSandboxView> createState() => _SMSSandboxViewState();
}

class _SMSSandboxViewState extends State<SMSSandboxView> {
  final _smsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  void _submitSMS() async {
    final smsText = _smsController.text.trim();
    if (smsText.isEmpty) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final success = await provider.parseSMS(token, smsText);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction successfully parsed and added from SMS!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to parse SMS. Ensure it contains an amount and matching keywords (credited/spent/debited).'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final parsedSMS = financeProvider.parsedSMSData;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'SMS Sandbox Simulator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste typical automated bank transaction alerts to simulate automated parsing',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Sandbox Form Card
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
                          Icon(Icons.sms_outlined, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Enter SMS Notification',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _smsController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Alert: Rs. 1,200 spent on HDFC Credit Card at Amazon. debited on 2026-06-19.',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: financeProvider.isSMSParsing ? null : _submitSMS,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: financeProvider.isSMSParsing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simulate SMS Parsing',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Examples Section
              const Text(
                'Try these example formats:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildExampleCard('₹ 250 spent at Swiggy using Axis Bank card'),
              const SizedBox(height: 8),
              _buildExampleCard('Your account HDFC has been credited Rs. 15,000 for Freelance'),
              const SizedBox(height: 8),
              _buildExampleCard('Paid Rs. 120 to Swiggy'),
              const SizedBox(height: 24),

              // Parse Result Card
              if (parsedSMS != null) ...[
                const Text(
                  'Last Parse Results:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultField('Amount', '₹ ${parsedSMS['amount'] ?? 'N/A'}'),
                      const Divider(color: Colors.white12),
                      _buildResultField('Type', parsedSMS['type']?.toString().toUpperCase() ?? 'N/A'),
                      const Divider(color: Colors.white12),
                      _buildResultField('Category', parsedSMS['category'] ?? 'Others'),
                      const Divider(color: Colors.white12),
                      _buildResultField('Merchant / Info', parsedSMS['merchant'] ?? 'Unknown'),
                      const Divider(color: Colors.white12),
                      _buildResultField('Detected Bank', parsedSMS['bank'] ?? 'Unknown'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            financeProvider.clearSMS();
                          },
                          child: const Text('Clear Log', style: TextStyle(color: Color(0xFF6366F1))),
                        ),
                      )
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleCard(String example) {
    return InkWell(
      onTap: () {
        setState(() {
          _smsController.text = example;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF131C33),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                example,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
