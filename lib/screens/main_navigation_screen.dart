// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/desktop_sidebar.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'pos_screen.dart';
import 'reports_screen.dart';
import 'printer_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // ── Mobile / tablet bottom-navigation state (UNCHANGED behaviour) ──────
  int _currentIndex = 0;

  // Define the screens for bottom navigation
  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const ProductsScreen(), // Index 1
    const PosScreen(), // Index 2
    const ProfileScreen(), // Index 3 - New Bill
  ];

  // ── Desktop shell state (web wide layout only) ─────────────────────────
  int _deskIndex = 0;
  // Lazily build desktop pages so heavy screens (e.g. printer scanning)
  // only initialise once the user actually opens them.
  final Set<int> _deskBuilt = {0};

  // Desktop screen order must match `desktopNavItems` in DesktopSidebar:
  // Dashboard, New Bill, Products, Reports, Printer, Profile.
  static const List<Widget> _deskScreens = [
    DashboardScreen(),
    PosScreen(),
    ProductsScreen(),
    ReportsScreen(),
    PrinterScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (Responsive.useDesktopShell(context)) {
      return _buildDesktopShell();
    }
    return _buildMobileShell();
  }

  // ── Mobile / tablet — original layout, untouched ───────────────────────
  Widget _buildMobileShell() {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.mutedForeground,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Bill',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── Desktop web — persistent sidebar + content area ────────────────────
  Widget _buildDesktopShell() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSidebar(
            currentIndex: _deskIndex,
            onSelect: (i) => setState(() {
              _deskIndex = i;
              _deskBuilt.add(i);
            }),
          ),
          Expanded(
            child: IndexedStack(
              index: _deskIndex,
              children: List.generate(
                _deskScreens.length,
                (i) => _deskBuilt.contains(i)
                    ? _deskScreens[i]
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
