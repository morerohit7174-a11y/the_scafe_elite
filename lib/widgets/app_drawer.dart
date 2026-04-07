// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  LoginProvider loginProvider = LoginProvider();

  @override
  void initState() {
    super.initState();
    loginProvider = context.read<LoginProvider>();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    loginProvider = context.watch<LoginProvider>();
    return Drawer(
      backgroundColor: AppTheme.card,
      width: 280,
      child: Column(
        children: [
          // ── Drawer Header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Cafe Elite',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.foreground,
                          ),
                        ),
                        Text(
                          'Navigation',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu Items ───────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                  current: route,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                ),
                _DrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'New Bill',
                  route: '/pos',
                  current: route,
                  onTap: () => Navigator.pushReplacementNamed(context, '/pos'),
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  route: '/products',
                  current: route,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/products'),
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  route: '/reports',
                  current: route,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/reports'),
                ),
                _DrawerItem(
                  icon: Icons.print_outlined,
                  label: 'Printer',
                  route: '/printer',
                  current: route,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/printer'),
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  route: '/profile',
                  current: route,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/profile'),
                ),
                const Divider(color: AppTheme.border, height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text('Info',
                    style: GoogleFonts.lato(
                      fontSize: 11, color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
                ),
                _DrawerItem(
                  icon: Icons.info_outline,
                  label: 'About',
                  route: '',
                  current: route,
                  onTap: () => _showAbout(context)),
            
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────
          Container(height: 1, color: AppTheme.border),

          // ── Logout Button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context,),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.destructive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

   void _showAbout(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('The Cafe Elite',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Premium Billing Software',
              style: GoogleFonts.lato(
                color: AppTheme.mutedForeground)),
            const SizedBox(height: 8),
            Text('Version: 1.0.0',
              style: GoogleFonts.lato(fontSize: 12)),
            Text('Dahiwadi, Maharashtra - 415508',
              style: GoogleFonts.lato(fontSize: 12)),
            Text('Contact: Sagar Katte',
              style: GoogleFonts.lato(fontSize: 12)),
            Text('Phone: 8087553246',
              style: GoogleFonts.lato(
                fontSize: 12, color: AppTheme.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context,) {
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
            onPressed: () async{
               await loginProvider.logout();
                            
            Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = route == current;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border(
                left: BorderSide(color: AppTheme.primary, width: 3),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isActive
                        ? AppTheme.primary
                        : AppTheme.mutedForeground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.foreground,
                      )),
                ),
                if (isActive)
                  Icon(Icons.check_circle,
                      size: 16, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
