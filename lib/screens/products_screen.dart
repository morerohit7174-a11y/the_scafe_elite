// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../models/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search   = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductsProvider>();
    final filtered = prov.products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase()) ||
          (p.nameHindi?.toLowerCase().contains(_search.toLowerCase()) ?? false);
      final matchCat = _category == 'All' || p.category == _category;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          const CafeEliteSliverAppBar(),

          // Title + Add button
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Products',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppTheme.foreground)),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            ),
          ),

          // Search + Category filter
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search products...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c, style: TextStyle(fontSize: 12)),
                        selected: c == _category,
                        selectedColor: AppTheme.primary,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    )).toList(),
                  ),
                ),
              ]),
            ),
          ),

          // Product list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No products found',
                          style: TextStyle(color: AppTheme.mutedForeground)),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final p = filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.5)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(
                                p.nameHindi != null && p.nameHindi!.isNotEmpty
                                    ? p.nameHindi![0] : p.name[0],
                                style: GoogleFonts.lato(
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: AppTheme.primary))),
                            ),
                            title: Text(p.name,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              '${p.category} • ₹${p.price.toStringAsFixed(0)}',
                              style: GoogleFonts.lato(
                                fontSize: 12, color: AppTheme.mutedForeground)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: p.isAvailable,
                                  activeThumbColor: AppTheme.primary,
                                  onChanged: (_) =>
                                      prov.toggleAvailability(p.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: AppTheme.primary,
                                  onPressed: () => _showForm(context, product: p)),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: AppTheme.destructive,
                                  onPressed: () => _confirmDelete(context, p)),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        onSave: (p) {
          final prov = context.read<ProductsProvider>();
          if (product != null) {
            prov.updateProduct(product.id, p);
          } else {
            prov.addProduct(p.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString()));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Product'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ProductsProvider>().deleteProduct(p.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.destructive))),
        ],
      ),
    );
  }
}
