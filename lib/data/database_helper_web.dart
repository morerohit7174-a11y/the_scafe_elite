// lib/data/database_helper_web.dart
// Web platform sathi — SharedPreferences use hoto (IndexedDB internally)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../models/order_item.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  static const _billsKey      = 'bills_data';
  static const _holdOrdersKey = 'hold_orders_data';

  // ── Bills ──────────────────────────────────────────────────────────────────
  Future<void> insertBill(Bill bill) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _getBillsList(prefs);
    list.insert(0, _billToMap(bill));
    await prefs.setString(_billsKey, jsonEncode(list));
  }

  

  Future<List<Bill>> getAllBills() async {
    final prefs = await SharedPreferences.getInstance();
    return _getBillsList(prefs).map(_mapToBill).toList();
  }

  Future<List<Bill>> getBillsByDate(DateTime date) async {
    final all = await getAllBills();
    return all.where((b) =>
      b.createdAt.year  == date.year &&
      b.createdAt.month == date.month &&
      b.createdAt.day   == date.day).toList();
  }

  List<Map<String, dynamic>> _getBillsList(SharedPreferences prefs) {
    final raw = prefs.getString(_billsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _billToMap(Bill bill) => {
    'id':           bill.id,
    'items':        bill.items.map((i) => i.toJson()).toList(),
    'subtotal':     bill.subtotal,
    'cgst':         bill.cgst,
    'sgst':         bill.sgst,
    'totalTax':     bill.totalTax,
    'grandTotal':   bill.grandTotal,
    'paymentMode':  bill.paymentMode.name,
    'createdAt':    bill.createdAt.toIso8601String(),
    'customerName': bill.customerName,
    'customerPhone':bill.customerPhone,
  };

  Bill _mapToBill(Map<String, dynamic> m) => Bill(
    userId: m['userId'] as String,
    id:           m['id'],
    items:        (m['items'] as List)
                    .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                    .toList(),
    subtotal:    (m['subtotal']   as num).toDouble(),
    cgst:        (m['cgst']       as num).toDouble(),
    sgst:        (m['sgst']       as num).toDouble(),
    totalTax:    (m['totalTax']   as num).toDouble(),
    grandTotal:  (m['grandTotal'] as num).toDouble(),
    paymentMode:  PaymentMode.values.byName(m['paymentMode']),
    createdAt:    DateTime.parse(m['createdAt']),
    customerName: m['customerName'],
    customerPhone:m['customerPhone'],
  );

  // ── Hold Orders ────────────────────────────────────────────────────────────
  Future<void> insertHoldOrder(HoldOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _getHoldList(prefs);
    list.insert(0, _holdToMap(order));
    await prefs.setString(_holdOrdersKey, jsonEncode(list));
  }

  Future<void> updateHoldOrder(HoldOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _getHoldList(prefs);
    final idx   = list.indexWhere((h) => h['id'] == order.id);
    if (idx != -1) list[idx] = _holdToMap(order);
    await prefs.setString(_holdOrdersKey, jsonEncode(list));
  }

  Future<List<HoldOrder>> getHoldOrders() async {
    final prefs = await SharedPreferences.getInstance();
    return _getHoldList(prefs).map(_mapToHold).toList();
  }

  Future<void> deleteHoldOrder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _getHoldList(prefs)..removeWhere((h) => h['id'] == id);
    await prefs.setString(_holdOrdersKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> _getHoldList(SharedPreferences prefs) {
    final raw = prefs.getString(_holdOrdersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _holdToMap(HoldOrder o) => {
    'id':         o.id,
    'tableName':  o.tableName,
    'items':      o.items.map((i) => i.toJson()).toList(),
    'subtotal':   o.subtotal,
    'grandTotal': o.grandTotal,
    'createdAt':  o.createdAt.toIso8601String(),
  };

  HoldOrder _mapToHold(Map<String, dynamic> m) => HoldOrder(
    id:         m['id'],
    tableName:  m['tableName'],
    items:      (m['items'] as List)
                  .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                  .toList(),
    subtotal:  (m['subtotal']   as num).toDouble(),
    grandTotal:(m['grandTotal'] as num).toDouble(),
    createdAt:  DateTime.parse(m['createdAt']),
  );
}

// ── HoldOrder model ────────────────────────────────────────────────────────
class HoldOrder {
  final String          id;
  final String          tableName;
  final List<OrderItem> items;
  final double          subtotal;
  final double          grandTotal;
  final DateTime        createdAt;

  HoldOrder({
    required this.id,
    required this.tableName,
    required this.items,
    required this.subtotal,
    required this.grandTotal,
    required this.createdAt,
  });
}
