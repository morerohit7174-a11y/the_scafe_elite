// lib/data/database_helper.dart
// Platform-aware: Mobile → SQLite | Web → SharedPreferences

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../models/order_item.dart';
import '../models/product.dart';

// Mobile SQLite imports (not used on web)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  // ── Keys for Web (SharedPreferences) ──────────────────────────────────────
  static const _billsKey      = 'ce_bills';
  static const _holdOrdersKey = 'ce_holds';

  // ── Mobile: SQLite init ────────────────────────────────────────────────────
  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'cafe_elite_v1.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int v) async {
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY, items_json TEXT, subtotal REAL,
        cgst REAL, sgst REAL, total_tax REAL, grand_total REAL,
        payment_mode TEXT, created_at TEXT,
        customer_name TEXT, customer_phone TEXT)''');
    await db.execute('''
      CREATE TABLE hold_orders (
        id TEXT PRIMARY KEY, table_name TEXT, items_json TEXT,
        subtotal REAL, grand_total REAL, created_at TEXT)''');
  }

  // ── BILLS ──────────────────────────────────────────────────────────────────
  Future<void> insertBill(Bill bill) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list  = _webGetList(prefs, _billsKey);
      list.insert(0, _billToMap(bill));
      await prefs.setString(_billsKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert('bills', {
        'id': bill.id,
        'items_json':    jsonEncode(bill.items.map((i) => i.toJson()).toList()),
        'subtotal':      bill.subtotal,
        'cgst':          bill.cgst,
        'sgst':          bill.sgst,
        'total_tax':     bill.totalTax,
        'grand_total':   bill.grandTotal,
        'payment_mode':  bill.paymentMode.name,
        'created_at':    bill.createdAt.toIso8601String(),
        'customer_name': bill.customerName,
        'customer_phone':bill.customerPhone,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Bill>> getAllBills() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return _webGetList(prefs, _billsKey).map(_mapToBill).toList();
    } else {
      final db   = await database;
      final rows = await db.query('bills', orderBy: 'created_at DESC');
      return rows.map(_rowToBill).toList();
    }
  }

  Future<List<Bill>> getBillsByDate(DateTime date) async {
    final all = await getAllBills();
    return all.where((b) =>
      b.createdAt.year  == date.year &&
      b.createdAt.month == date.month &&
      b.createdAt.day   == date.day).toList();
  }

  // ── HOLD ORDERS ────────────────────────────────────────────────────────────
  Future<void> insertHoldOrder(HoldOrder order) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list  = _webGetList(prefs, _holdOrdersKey);
      list.insert(0, _holdToMap(order));
      await prefs.setString(_holdOrdersKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert('hold_orders', {
        'id':         order.id,
        'table_name': order.tableName,
        'items_json': jsonEncode(order.items.map((i) => i.toJson()).toList()),
        'subtotal':   order.subtotal,
        'grand_total':order.grandTotal,
        'created_at': order.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateHoldOrder(HoldOrder order) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list  = _webGetList(prefs, _holdOrdersKey);
      final idx   = list.indexWhere((h) => h['id'] == order.id);
      if (idx != -1) list[idx] = _holdToMap(order);
      await prefs.setString(_holdOrdersKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.update('hold_orders', {
        'table_name': order.tableName,
        'items_json': jsonEncode(order.items.map((i) => i.toJson()).toList()),
        'subtotal':   order.subtotal,
        'grand_total':order.grandTotal,
      }, where: 'id = ?', whereArgs: [order.id]);
    }
  }

  Future<List<HoldOrder>> getHoldOrders() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return _webGetList(prefs, _holdOrdersKey).map(_mapToHold).toList();
    } else {
      final db   = await database;
      final rows = await db.query('hold_orders', orderBy: 'created_at DESC');
      return rows.map((row) {
        final list = jsonDecode(row['items_json'] as String) as List<dynamic>;
        return HoldOrder(
          id:         row['id']         as String,
          tableName:  row['table_name'] as String,
          items:      list.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
          subtotal:  (row['subtotal']    as num).toDouble(),
          grandTotal:(row['grand_total'] as num).toDouble(),
          createdAt:  DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    }
  }

  Future<void> deleteHoldOrder(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list  = _webGetList(prefs, _holdOrdersKey)
          ..removeWhere((h) => h['id'] == id);
      await prefs.setString(_holdOrdersKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.delete('hold_orders', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ── Web helpers ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _webGetList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  // ── Converters ─────────────────────────────────────────────────────────────
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
    userId:       m['userId'] as String,
    id:           m['id'] as String,
    items:        (m['items'] as List)
                    .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                    .toList(),
    subtotal:    (m['subtotal']   as num).toDouble(),
    cgst:        (m['cgst']       as num).toDouble(),
    sgst:        (m['sgst']       as num).toDouble(),
    totalTax:    (m['totalTax']   as num).toDouble(),
    grandTotal:  (m['grandTotal'] as num).toDouble(),
    paymentMode:  PaymentMode.values.byName(m['paymentMode'] as String),
    createdAt:    DateTime.parse(m['createdAt'] as String),
    customerName: m['customerName'] as String?,
    customerPhone:m['customerPhone'] as String?,
  );

  Bill _rowToBill(Map<String, dynamic> row) {
    final list = jsonDecode(row['items_json'] as String) as List<dynamic>;
    return Bill(
      userId:       row['userId']       as String,
      id:           row['id']           as String,
      items:        list.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
      subtotal:    (row['subtotal']      as num).toDouble(),
      cgst:        (row['cgst']          as num).toDouble(),
      sgst:        (row['sgst']          as num).toDouble(),
      totalTax:    (row['total_tax']     as num).toDouble(),
      grandTotal:  (row['grand_total']   as num).toDouble(),
      paymentMode:  PaymentMode.values.byName(row['payment_mode'] as String),
      createdAt:    DateTime.parse(row['created_at']   as String),
      customerName: row['customer_name']  as String?,
      customerPhone:row['customer_phone'] as String?,
    );
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
    id:         m['id']        as String,
    tableName:  m['tableName'] as String,
    items:      (m['items'] as List)
                  .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                  .toList(),
    subtotal:  (m['subtotal']   as num).toDouble(),
    grandTotal:(m['grandTotal'] as num).toDouble(),
    createdAt:  DateTime.parse(m['createdAt'] as String),
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
