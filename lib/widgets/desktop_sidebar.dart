// lib/widgets/desktop_sidebar.dart
//
// Persistent left-hand navigation rail used ONLY on the desktop web shell
// (width >= 1024px). It drives the in-shell IndexedStack via [onSelect] and
// reuses the exact Cafe Elite theme / branding. No business logic lives here.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import '../theme/app_theme.dart';

class DesktopNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const DesktopNavItem(this.icon, this.activeIcon, this.label);
}

const desktopNavItems = <DesktopNavItem>[
  DesktopNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  DesktopNavItem(Icons.add_circle_outline, Icons.add_circle, 'New Bill'),
  DesktopNavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
  DesktopNavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),
  DesktopNavItem(Icons.print_outlined, Icons.print, 'Printer'),
  DesktopNavItem(Icons.person_outline, Icons.person, 'Profile'),
];

class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // ── Brand header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              border:
                  const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/image.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primary,
                        child: const Icon(Icons.coffee,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('The Cafe Elite',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.foreground,
                          )),
                      Text('POS Billing',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nav items ──────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: desktopNavItems.length,
              itemBuilder: (_, i) {
                final item = desktopNavItems[i];
                final active = i == currentIndex;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: active
                        ? const Border(
                            left:
                                BorderSide(color: AppTheme.primary, width: 3))
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Icon(active ? item.activeIcon : item.icon,
                                size: 21,
                                color: active
                                    ? AppTheme.primary
                                    : AppTheme.mutedForeground),
                            const SizedBox(width: 14),
                            Text(item.label,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? AppTheme.primary
                                      : AppTheme.foreground,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: AppTheme.border, height: 1),

          // ── Logout ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.destructive,
                  side: const BorderSide(color: AppTheme.destructive),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final loginProvider = context.read<LoginProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await loginProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );
  }
}
