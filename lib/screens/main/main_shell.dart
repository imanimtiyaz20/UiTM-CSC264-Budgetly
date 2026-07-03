import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../jars/jars_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    OverviewScreen(),
    TransactionListScreen(),
    JarsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: "Home",
              index: 0,
              isDark: isDark,
            ),
            _navItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: "Activity",
              index: 1,
              isDark: isDark,
            ),
            _navItem(
              icon: Icons.savings_outlined,
              activeIcon: Icons.savings,
              label: "Jars",
              index: 2,
              isDark: isDark,
            ),
            _navItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: "Settings",
              index: 3,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isActive = _currentIndex == index;

    final color = isActive
        ? (isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00897B))
        : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),

      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}