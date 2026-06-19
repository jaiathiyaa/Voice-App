import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'views/auth_view.dart';
import 'views/dashboard_view.dart';
import 'views/transactions_view.dart';
import 'views/voice_entry_view.dart';
import 'views/sms_sandbox_view.dart';
import 'views/budget_view.dart';
import 'views/ai_coach_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D1A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF131C33),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated) {
      return const MainNavigationLayout();
    } else {
      return const AuthView();
    }
  }
}

class MainNavigationLayout extends StatefulWidget {
  const MainNavigationLayout({super.key});

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const DashboardView(),
    const TransactionsView(),
    const VoiceEntryView(),
    const SMSSandboxView(),
    const BudgetView(),
    const AICoachView(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(title: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
    NavigationItem(title: 'Transactions', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
    NavigationItem(title: 'Voice Entry', icon: Icons.settings_voice_outlined, activeIcon: Icons.settings_voice),
    NavigationItem(title: 'SMS Sandbox', icon: Icons.sms_outlined, activeIcon: Icons.sms),
    NavigationItem(title: 'Budgets', icon: Icons.track_changes_outlined, activeIcon: Icons.track_changes),
    NavigationItem(title: 'AI Coach', icon: Icons.psychology_outlined, activeIcon: Icons.psychology),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings_voice, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Voice Finance Tracker',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              const Text(
                'Member',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  authProvider.logout();
                },
                tooltip: 'Log Out',
              ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;
          if (isLargeScreen) {
            // Sidebar for Large Screens
            return Row(
              children: [
                _buildSidebar(),
                const VerticalDivider(color: Colors.white10, width: 1),
                Expanded(
                  child: _views[_currentIndex],
                ),
              ],
            );
          } else {
            // Bottom navigation for Small Screens
            return _views[_currentIndex];
          }
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;
          if (isLargeScreen) {
            return const SizedBox.shrink();
          } else {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF131C33),
              selectedItemColor: const Color(0xFF6366F1),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: _navItems
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.activeIcon),
                        label: item.title,
                      ))
                  .toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0B0F19),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MENU',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _currentIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    selected: isSelected,
                    selectedColor: Colors.white,
                    iconColor: const Color(0xFF94A3B8),
                    textColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;

  NavigationItem({required this.title, required this.icon, required this.activeIcon});
}
