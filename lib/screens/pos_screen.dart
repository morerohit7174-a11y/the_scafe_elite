// lib/screens/pos_screen.dart
import 'package:cafe_elite/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/bills_provider.dart';
import '../models/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cart_panel.dart';
import '../widgets/bill_preview_dialog.dart';
import '../widgets/hold_orders_panel.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _selectedCategory = 'All';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().availableProducts;
    final cart     = context.watch<CartProvider>();
    final holds    = context.watch<BillsProvider>().holdOrders;

    final filtered = products.where((p) {
      final matchCat    = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          (p.nameHindi?.toLowerCase().contains(_search.toLowerCase()) ?? false);
      return matchCat && matchSearch;
    }).toList();

    return Scaffold(
      body: SafeArea(child: Column(children: [
        const AppHeader(),

        // Editing hold order banner
        if (cart.isEditingHold)
          Container(
            color: AppTheme.primary.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.edit, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Editing: "${cart.tableName}"',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13))),
              TextButton(onPressed: cart.clearCart,
                child: const Text('Cancel Edit', style: TextStyle(color: AppTheme.destructive, fontSize: 12))),
            ]),
          ),

        Expanded(child: Row(children: [
          // ── Product panel ──────────────────────────────────────────────
          Expanded(child: Column(children: [
            // Search + Holds btn
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 16),
                            onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                        : null,
                  ),
                )),
                const SizedBox(width: 10),
                Badge(
                  label: Text('${holds.length}'),
                  isLabelVisible: holds.isNotEmpty,
                  backgroundColor: AppTheme.primary,
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const HoldOrdersPanel()),
                    icon: const Icon(Icons.pause_circle_outline, size: 17),
                    label: const Text('Holds', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ]),
            ),

            // Category chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final sel = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 12,
                        color: sel ? Colors.white : AppTheme.mutedForeground)),
                    selected: sel,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),

            // Product grid
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off, size: 40, color: AppTheme.mutedForeground),
                      SizedBox(height: 8),
                      Text('No items found', style: TextStyle(color: AppTheme.mutedForeground)),
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p   = filtered[i];
                        final qty = cart.items
                            .where((x) => x.product.id == p.id)
                            .fold(0, (s, x) => s + x.quantity);
                        return _ProductTile(
                          product: p, qty: qty,
                          onTap: () => cart.addItem(p),
                        );
                      },
                    ),
            ),
          ])),

          // ── Cart panel (tablet/desktop) ────────────────────────────────
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 340,
              child: CartPanel(onCheckout: () => _checkout(context)),
            ),
        ])),
      ])),
      floatingActionButton: MediaQuery.of(context).size.width <= 600
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart (${cart.itemCount})'),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        builder: (_, __) => CartPanel(onCheckout: () {
          Navigator.pop(context);
          _checkout(context);
        }),
      ),
    );
  }

  void _checkout(BuildContext context) async{
    final cart      = context.read<CartProvider>();
    final billsProv = context.read<BillsProvider>();
    if (cart.items.isEmpty) return;

    final bill = cart.generateBill();
    if (cart.isEditingHold) {
      billsProv.deleteHoldOrder(cart.editingHold!.id);
    }
    await FirebaseService.saveBill(bill);
    billsProv.addBill(bill);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillPreviewDialog(
        bill: bill,
        onNewOrder: () { cart.clearCart(); Navigator.pop(context); },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final dynamic product;
  final int qty;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.qty, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: qty > 0 ? AppTheme.primary.withValues(alpha: 0.13) : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qty > 0 ? AppTheme.primary : AppTheme.border.withValues(alpha: 0.5),
          width: qty > 0 ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis, maxLines: 2),
          if (product.nameHindi != null)
            Text(product.nameHindi!,
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('₹${product.price.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppTheme.primary)),
        ]),
        if (qty > 0)
          Positioned(top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Text('$qty', style: const TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.bold)),
            )),
      ]),
    ),
  );
}
