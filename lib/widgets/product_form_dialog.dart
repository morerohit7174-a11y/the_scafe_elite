import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/constants.dart';
import '../theme/app_theme.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final void Function(Product) onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _nameHindiCtrl;
  late TextEditingController _priceCtrl;
  late String _category;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _nameHindiCtrl = TextEditingController(text: widget.product?.nameHindi ?? '');
    _priceCtrl = TextEditingController(text: widget.product?.price.toString() ?? '');
    // Set category to product's category if it exists in the list (excluding 'All'), otherwise use first available
    final availableCategories = categories.where((c) => c != 'All').toList();
    final productCategory = widget.product?.category ?? '';
    _category = availableCategories.contains(productCategory) ? productCategory : (availableCategories.isNotEmpty ? availableCategories[0] : 'Pizza');
    _isAvailable = widget.product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameHindiCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = categories.where((c) => c != 'All').toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product != null ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
            const SizedBox(height: 12),
            TextField(controller: _nameHindiCtrl, decoration: const InputDecoration(labelText: 'Name in Hindi (Optional)')),
            const SizedBox(height: 12),
            TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹) *'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Available for Sale'),
              value: _isAvailable,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _isAvailable = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
                    final product = Product(
                      id: widget.product?.id ?? '',
                      name: _nameCtrl.text,
                      nameHindi: _nameHindiCtrl.text.isEmpty ? null : _nameHindiCtrl.text,
                      price: double.tryParse(_priceCtrl.text) ?? 0,
                      category: _category,
                      isAvailable: _isAvailable, size: widget.product?.size ?? 'Medium',
                    );
                    widget.onSave(product);
                    Navigator.pop(context);
                  },
                  child: Text(widget.product != null ? 'Update' : 'Add Product'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
