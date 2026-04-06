// lib/screens/dashboard_screen.dart
import 'package:cafe_elite/models/bill.dart';
import 'package:cafe_elite/providers/login_provider.dart';
import 'package:cafe_elite/widgets/db_constants.dart';
import 'package:cafe_elite/widgets/pref_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bills_provider.dart';
import '../providers/products_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/stats_card.dart';
import '../widgets/hold_orders_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  LoginProvider loginProvider = LoginProvider();

   Future<void> logout() async {
    await loginProvider.logout();
  }

  @override
  void initState() {
    super.initState();
    loginProvider = context.read<LoginProvider>();
  }

  @override
  Widget build(BuildContext context) {
    loginProvider = context.watch<LoginProvider>();
    final billsProv  = context.watch<BillsProvider>();
    final prodsProv  = context.watch<ProductsProvider>();
    final today      = billsProv.getTodaysSales();
    final recent     = billsProv.getRecentBills(5);
    final holds      = billsProv.holdOrders;
    final availCount = prodsProv.availableProducts.length;
    final totalCount = prodsProv.products.length;

    

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ─────────────────────────────────────────
          const CafeEliteSliverAppBar(),

          // ── Content ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Welcome row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back! ☕',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24, fontWeight: FontWeight.bold,
                              color: AppTheme.foreground)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                            style: GoogleFonts.lato(
                              color: AppTheme.mutedForeground, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (holds.isNotEmpty) ...[
                          Badge(
                            label: Text('${holds.length}'),
                            backgroundColor: AppTheme.primary,
                            child: OutlinedButton.icon(
                              onPressed: () => showDialog(context: context,
                                  builder: (_) => const HoldOrdersPanel()),
                              icon: const Icon(Icons.pause_circle_outline, size: 15),
                              label: const Text('Holds', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/pos'),
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text('New Order'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        ),
                         ElevatedButton.icon(
                          onPressed: ()async{
                            await loginProvider.logout();
                            
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text('LogOut'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats
                Text("Today's Summary",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppTheme.foreground)),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    StatsCard(title: "Today's Sales",
                      value: '₹${today.totalSales.toStringAsFixed(2)}',
                      subtitle: '${today.totalOrders} orders',
                      icon: Icons.currency_rupee),
                    StatsCard(title: 'Cash Sales',
                      value: '₹${today.cashSales.toStringAsFixed(2)}',
                      icon: Icons.money),
                    StatsCard(title: 'UPI Sales',
                      value: '₹${today.upiSales.toStringAsFixed(2)}',
                      icon: Icons.smartphone),
                    StatsCard(title: 'Card Sales',
                      value: '₹${today.cardSales.toStringAsFixed(2)}',
                      icon: Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 10),

                Row(children: [
                  Expanded(child: StatsCard(title: 'Total Orders',
                    value: '${today.totalOrders}', icon: Icons.shopping_bag)),
                  const SizedBox(width: 10),
                  Expanded(child: StatsCard(title: 'Products',
                    value: '$availCount', subtitle: 'of $totalCount total',
                    icon: Icons.inventory_2)),
                  if (holds.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(
                      onTap: () => showDialog(context: context,
                          builder: (_) => const HoldOrdersPanel()),
                      child: StatsCard(title: 'Hold Orders',
                        value: '${holds.length}', subtitle: 'Tap to view',
                        icon: Icons.pause_circle),
                    )),
                  ],
                ]),
                const SizedBox(height: 20),

                // Recent orders
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Orders',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/reports'),
                              child: const Text('View All')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 40, color: AppTheme.mutedForeground),
                              SizedBox(height: 8),
                              Text('No orders yet today',
                                style: TextStyle(color: AppTheme.mutedForeground)),
                            ]),
                          ))
                        else
                          ...recent.map((bill) {
                            final modeColor = switch (bill.paymentMode) {
                              PaymentMode.cash => Colors.green,
                              PaymentMode.upi  => Colors.blue,
                              PaymentMode.card => Colors.purple,
                            };
                            final modeIcon = switch (bill.paymentMode) {
                              PaymentMode.cash => Icons.money,
                              PaymentMode.upi  => Icons.smartphone,
                              PaymentMode.card => Icons.credit_card,
                            };
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: modeColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(modeIcon, size: 18,
                                      color: modeColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${bill.items.length} item${bill.items.length > 1 ? "s" : ""}',
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                    Text(
                                      '${DateFormat('HH:mm').format(bill.createdAt)} · '
                                      '${bill.paymentMode.name.toUpperCase()}',
                                      style: GoogleFonts.lato(
                                        color: AppTheme.mutedForeground,
                                        fontSize: 11)),
                                  ],
                                )),
                                Text(
                                '₹${bill.subtotal.toStringAsFixed(2)}', // ✅ change here
                                  style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primary),
                                ),
                              ]),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
