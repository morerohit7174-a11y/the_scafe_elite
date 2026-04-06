// lib/widgets/cart_panel.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/bills_provider.dart';
import '../models/bill.dart';
import '../models/constants.dart';
import '../theme/app_theme.dart';

class CartPanel extends StatelessWidget {
  final VoidCallback onCheckout;
  const CartPanel({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.items.fold<double>(
  0,
  (sum, item) => sum + (item.quantity * item.product.price),
);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Order',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: cart.clearCart,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Clear',
                      style: GoogleFonts.lato(
                        color: AppTheme.destructive, fontSize: 12)),
                  ),
              ],
            ),
          ),

          // ── Table Selector ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: DropdownButtonFormField<String>(
              initialValue: cart.tableName,
              decoration: InputDecoration(
                labelText: 'Table / Order Type',
                labelStyle: GoogleFonts.lato(fontSize: 12),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              dropdownColor: AppTheme.surface,
              style: GoogleFonts.lato(
                  color: AppTheme.foreground, fontSize: 13),
              items: [
                'Walk-in', 'Table 1', 'Table 2', 'Table 3',
                'Table 4', 'Table 5','Table 6','Table 7','Table 8','Table 9','Table 10', 'Takeaway', 'Delivery'
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => cart.setTableName(v ?? 'Walk-in'),
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // ── Items List ────────────────────────────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 44, color: AppTheme.mutedForeground),
                        const SizedBox(height: 10),
                        Text('Cart is empty',
                          style: GoogleFonts.lato(
                            color: AppTheme.mutedForeground, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Tap items to add',
                          style: GoogleFonts.lato(
                            color: AppTheme.mutedForeground, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.product.name,
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                    Text(
                                      '₹${(item.quantity * item.product.price).toStringAsFixed(0)} each',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: AppTheme.mutedForeground),
                                    ),
                                  ],
                                ),
                              ),
                              // Qty controls
                              _QtyBtn(Icons.remove,
                                  () => cart.decrementQuantity(item.product.id)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item.quantity}',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                              ),
                              _QtyBtn(Icons.add,
                                  () => cart.incrementQuantity(item.product.id),
                                  filled: true),
                              const SizedBox(width: 8),
                              Text(
                                '₹${item.total.toStringAsFixed(0)}',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),  
                        ),
                      );
                    },
                  ),
          ),

          // ── Bill Summary + Actions ─────────────────────────────────────
          if (cart.items.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.border),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment mode
                  Row(
                    children: PaymentMode.values.map((mode) {
                      final sel = cart.paymentMode == mode;
                      final icons = {
                        PaymentMode.cash: Icons.money,
                        PaymentMode.upi:  Icons.smartphone,
                        PaymentMode.card: Icons.credit_card,
                      };
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => cart.setPaymentMode(mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primary.withValues(alpha: 0.15)
                                    : null,
                                border: Border.all(
                                  color: sel ? AppTheme.primary : AppTheme.border,
                                  width: sel ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icons[mode]!, size: 16,
                                    color: sel
                                        ? AppTheme.primary
                                        : AppTheme.mutedForeground),
                                  const SizedBox(height: 2),
                                  Text(mode.name.toUpperCase(),
                                    style: GoogleFonts.lato(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: sel
                                          ? AppTheme.primary
                                          : AppTheme.mutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Totals
                  _SumRow('Subtotal',
  '₹${subtotal.toStringAsFixed(2)}'),
                  // _SumRow('CGST ($cgstRate%)',
                  //     '₹${cart.cgst.toStringAsFixed(2)}'),
                  // _SumRow('SGST ($sgstRate%)',
                  //     '₹${cart.sgst.toStringAsFixed(2)}'),
                  const Divider(height: 10, color: AppTheme.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL',
                        style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('₹${subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hold + Complete buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _holdOrder(context, cart),
                        icon: const Icon(Icons.pause_circle_outline, size: 15),
                        label: Text(
                          cart.isEditingHold ? 'Update' : 'Hold',
                          style: GoogleFonts.lato(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success),
                            child: Text('Complete Order',
                              style: GoogleFonts.lato(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _holdOrder(BuildContext context, CartProvider cart) async {
    if (cart.items.isEmpty) return;
    final hold      = cart.generateHoldOrder();
    final billsProv = context.read<BillsProvider>();
    if (cart.isEditingHold) {
      await billsProv.updateHoldOrder(hold);
    } else {
      await billsProv.holdOrder(hold);
    }
    cart.clearCart();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order "${hold.tableName}" held ✅',
          style: GoogleFonts.lato()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyBtn(this.icon, this.onTap, {this.filled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: filled ? AppTheme.primary : AppTheme.cardLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? AppTheme.primary : AppTheme.border),
      ),
      child: Icon(icon, size: 14,
        color: filled ? Colors.white : AppTheme.foreground),
    ),
  );
}

class _SumRow extends StatelessWidget {
  final String l, v;
  const _SumRow(this.l, this.v);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: GoogleFonts.lato(
            fontSize: 12, color: AppTheme.mutedForeground)),
        Text(v, style: GoogleFonts.lato(
            fontSize: 12, color: AppTheme.mutedForeground)),
      ],
    ),
  );
}
