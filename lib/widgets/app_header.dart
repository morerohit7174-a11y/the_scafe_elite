// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Logo image ───────────────────────────────────────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primary,
                    child:
                        const Icon(Icons.coffee, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── App name ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The Cafe Elite',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.foreground,
                  ),
                ),
                Text(
                  'Billing System',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Profile Button ───────────────────────────────────────
            _NavBtn(
                icon: Icons.person_outline,
                label: 'Profile',
                route: '/profile',
                current: route,
                screenW: screenW),
            const SizedBox(width: 4),

            // ── Menu Button ──────────────────────────────────────────
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: 'Menu',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SliverAppBar version ──────────────────────────────────────────────────────
class CafeEliteSliverAppBar extends StatelessWidget {
  const CafeEliteSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    final screenW = MediaQuery.of(context).size.width;

    return SliverAppBar(
      backgroundColor: AppTheme.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      elevation: 4,
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: 70,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            border:
                Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // ── Logo image ────────────────────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/image.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primary,
                        child: const Icon(Icons.coffee,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── App name ──────────────────────────────────────
                if (screenW > 360)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('The Cafe Elite',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.foreground)),
                      Text('Billing Software',
                          style: GoogleFonts.lato(
                              fontSize: 9,
                              color: AppTheme.mutedForeground,
                              letterSpacing: 0.5)),
                    ],
                  ),

                const Spacer(),

                // ── Nav buttons ───────────────────────────────────
                // _NavBtn(icon: Icons.dashboard_outlined,
                //     label: 'Dashboard', route: '/dashboard',
                //     current: route, screenW: screenW),
                // _NavBtn(icon: Icons.shopping_bag_outlined,
                //     label: 'New Bill', route: '/pos',
                //     current: route, screenW: screenW),
                // _NavBtn(icon: Icons.inventory_2_outlined,
                //     label: 'Products', route: '/products',
                //     current: route, screenW: screenW),
                // _NavBtn(icon: Icons.bar_chart_outlined,
                //     label: 'Reports', route: '/reports',
                //     current: route, screenW: screenW),
                // _NavBtn(icon: Icons.print_outlined,
                //     label: 'Printer', route: '/printer',
                //     current: route, screenW: screenW),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Button ────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label, route, current;
  final double screenW;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    required this.screenW,
  });

  @override
  Widget build(BuildContext context) {
    final active = route == current;
    final iconsOnly = screenW < 600;

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Material(
        color: active
            ? AppTheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!active) Navigator.pushReplacementNamed(context, route);
          },
          child: iconsOnly
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon,
                      size: 25,
                      color:
                          active ? AppTheme.primary : AppTheme.mutedForeground),
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 15,
                          color: active
                              ? AppTheme.primary
                              : AppTheme.mutedForeground),
                      const SizedBox(width: 5),
                      Text(label,
                          style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w400,
                              color: active
                                  ? AppTheme.primary
                                  : AppTheme.mutedForeground)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
