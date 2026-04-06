// lib/widgets/hold_orders_panel.dart

import 'package:cafe_elite/data/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bills_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class HoldOrdersPanel extends StatelessWidget {
  const HoldOrdersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final holds = context.watch<BillsProvider>().holdOrders;

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(children: [

          // 🔹 HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(children: [
              Icon(Icons.pause_circle, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text('Hold Orders (${holds.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // 🔹 LIST
          Expanded(
            child: holds.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause_circle_outline,
                            size: 52, color: AppTheme.mutedForeground),
                        SizedBox(height: 12),
                        Text('No held orders',
                            style: TextStyle(
                                color: AppTheme.mutedForeground,
                                fontSize: 15)),
                        SizedBox(height: 6),
                        Text('Hold an order from POS screen',
                            style: TextStyle(
                                color: AppTheme.mutedForeground,
                                fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: holds.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _HoldCard(
                      hold: holds[i],
                      onResume: () {
                        _resume(context, holds[i]);
                        Navigator.pop(context);
                      },
                      onEdit: () {
                        _edit(context, holds[i]);
                        Navigator.pop(context);
                      },
                      onDelete: () => _delete(context, holds[i].id),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  void _resume(BuildContext context, HoldOrder hold) {
    context.read<CartProvider>().loadHoldOrder(hold);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Resumed "${hold.tableName}"'),
      backgroundColor: AppTheme.success,
    ));
  }

  void _edit(BuildContext context, HoldOrder hold) {
    context.read<CartProvider>().loadHoldOrder(hold);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Editing "${hold.tableName}"'),
      backgroundColor: AppTheme.primary,
    ));
  }

  void _delete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Hold Order?'),
        content:
            const Text('This held order will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<BillsProvider>().deleteHoldOrder(id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );
  }
}

// 🔥 HOLD CARD FIXED
class _HoldCard extends StatelessWidget {
  final HoldOrder hold;
  final VoidCallback onResume, onEdit, onDelete;

  const _HoldCard({
    required this.hold,
    required this.onResume,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔹 TITLE
          Row(
            children: [
              Expanded(
                child: Text(
                  hold.tableName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                DateFormat('HH:mm · dd MMM')
                    .format(hold.createdAt),
                style: const TextStyle(
                    color: AppTheme.mutedForeground, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🔹 ITEMS
          Text(
            hold.items
                .map((i) => '${i.product.name} ×${i.quantity}')
                .join(', '),
            style: const TextStyle(
                color: AppTheme.mutedForeground, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // 🔥 FIXED PART (NO OVERFLOW)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Amount
              Text(
                '₹${hold.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Buttons (Wrap)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Btn(
                    label: 'Delete',
                    color: AppTheme.destructive,
                    icon: Icons.delete_outline,
                    onTap: onDelete,
                    outlined: true,
                  ),
                  _Btn(
                    label: 'Edit',
                    color: AppTheme.primary,
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                    outlined: true,
                  ),
                  _Btn(
                    label: 'Resume',
                    color: AppTheme.success,
                    icon: Icons.play_arrow,
                    onTap: onResume,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔹 BUTTON
class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _Btn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: outlined ? null : color,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: outlined ? color : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: outlined ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}