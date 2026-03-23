// ============================================================
// lib/screens/home_screen.dart
// ============================================================
// Shell screen that holds the Bottom Navigation Bar and swaps
// between the four main tab screens:
//   0. Dashboard  — live sensor overview
//   1. Feeding    — schedule management + quick dispense
//   2. Climate    — temperature/humidity details + device toggles
//   3. Logs       — activity history
//
// A floating "Settings" icon in the AppBar opens settings.
// ============================================================

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'feeding_screen.dart';
import 'climate_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Currently selected tab index ──────────────────────────────────────────
  int _currentIndex = 0;

  // ── The four tab screens — defined once so they keep their scroll state ───
  // Using const constructors where possible for performance.
  final List<Widget> _screens = const [
    DashboardScreen(),
    FeedingScreen(),
    ClimateScreen(),
    LogsScreen(),
  ];

  // ── Nav item definitions ──────────────────────────────────────────────────
  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.grain_outlined, activeIcon: Icons.grain, label: 'Feeding'),
    _NavItem(icon: Icons.thermostat_outlined, activeIcon: Icons.thermostat, label: 'Climate'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Logs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── App Bar ────────────────────────────────────────────────────────
      appBar: AppBar(
        title: Row(
          children: [
            // Small logo in the AppBar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('🐔', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('PoultryCare'),
          ],
        ),
        actions: [
          // Settings icon button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── Active tab body ───────────────────────────────────────────────
      // IndexedStack keeps all screens alive so scroll position is preserved.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          // elevation: 0 because we use a custom Container decoration above.
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Simple data class for nav item definitions ────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}