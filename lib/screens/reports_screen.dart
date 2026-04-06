// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bills_provider.dart';
import '../models/bill.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/stats_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillsProvider>();
    final sales = prov.getSalesByDate(_selectedDate);
    final bills = prov.getBillsByDate(_selectedDate);

    final grandTotal = bills.fold<double>(
      0,
      (sum, bill) => sum + bill.subtotal,
    );
    final avg =
        sales.totalOrders > 0 ? sales.totalSales / sales.totalOrders : 0.0;
    final isToday = DateFormat('yyyyMMdd').format(_selectedDate) ==
        DateFormat('yyyyMMdd').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          const CafeEliteSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title + date picker
                Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales Reports',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.foreground)),
                      Text('View your daily sales performance',
                          style: GoogleFonts.lato(
                              color: AppTheme.mutedForeground, fontSize: 13)),
                    ],
                  )),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 15),
                    label: Text(
                        isToday
                            ? 'Today'
                            : DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Stats grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                  children: [
                    StatsCard(
                        title: 'Total Sales',
                        value: '₹${sales.totalSales.toStringAsFixed(2)}',
                        subtitle: '${sales.totalOrders} orders',
                        icon: Icons.currency_rupee),
                    StatsCard(
                        title: 'Avg Order',
                        value: '₹${avg.toStringAsFixed(2)}',
                        icon: Icons.receipt_long),
                    StatsCard(
                        title: 'Total Orders',
                        value: '${sales.totalOrders}',
                        icon: Icons.shopping_bag),
                    StatsCard(
                        title: 'Cash',
                        value: '₹${sales.cashSales.toStringAsFixed(2)}',
                        icon: Icons.money),
                    StatsCard(
                        title: 'UPI',
                        value: '₹${sales.upiSales.toStringAsFixed(2)}',
                        icon: Icons.smartphone),
                    StatsCard(
                        title: 'Card',
                        value: '₹${sales.cardSales.toStringAsFixed(2)}',
                        icon: Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 HEADER
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Orders — ${isToday ? "Today" : DateFormat("dd MMM yyyy").format(_selectedDate)}',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${bills.length} bills',
                                style: const TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        if (bills.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 42,
                                    color: AppTheme.mutedForeground
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No orders on this date',
                                    style: TextStyle(
                                      color: AppTheme.mutedForeground,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _th('Bill ID', flex: 2),
                                _th('Time'),
                                _th('Items', flex: 3),
                                _th('Pay', flex: 2),
                                _th('Amount', flex: 2, right: true),
                              ],
                            ),
                          ),

                          // 🔹 LIST
                          ...bills.asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: _BillRow(
                                    bill: e.value,
                                    isEven: e.key.isEven,
                                    onTap: () => _showDetail(context, e.value),
                                  ),
                                ),
                              ),

                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'GRAND TOTAL',
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${grandTotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _th(String t, {int flex = 1, bool right = false}) => Expanded(
      flex: flex,
      child: Text(t,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground),
          textAlign: right ? TextAlign.right : TextAlign.left));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showDetail(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Order Detail',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
              '${bill.id} · ${DateFormat('dd MMM, HH:mm').format(bill.createdAt)}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.mutedForeground)),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border),
          ...bill.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(
                      child: Text('${item.product.name} ×${item.quantity}')),
                  Text('₹${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
              )),
          const Divider(color: AppTheme.border),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('₹${bill.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primary)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Payment',
                style: TextStyle(color: AppTheme.mutedForeground)),
            Text(bill.paymentMode.name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final Bill bill;
  final bool isEven;
  final VoidCallback onTap;
  const _BillRow(
      {required this.bill, required this.isEven, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final modeColor = switch (bill.paymentMode) {
      PaymentMode.cash => Colors.green,
      PaymentMode.upi => Colors.blue,
      PaymentMode.card => Colors.purple,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
            color: isEven
                ? AppTheme.surface.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text(
                  bill.id.length > 8
                      ? bill.id.substring(bill.id.length - 8)
                      : bill.id,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(DateFormat('HH:mm').format(bill.createdAt),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text(
                  bill.items
                      .map((i) => '${i.product.name}×${i.quantity}')
                      .join(', '),
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(bill.paymentMode.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: modeColor)))),
          Expanded(
              flex: 2,
              child: Text('₹${bill.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13))),
        ]),
      ),
    );
  }
}
