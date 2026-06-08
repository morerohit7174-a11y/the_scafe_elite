// lib/providers/bills_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../data/database_helper.dart';
import '../services/firebase_service.dart';

class DailySales {
  final String date;
  final double totalSales;
  final int    totalOrders;
  final double cashSales;
  final double upiSales;
  final double cardSales;
  DailySales({
    required this.date, required this.totalSales,
    required this.totalOrders, required this.cashSales,
    required this.upiSales, required this.cardSales});
}
class BillsProvider extends ChangeNotifier {
  final _db = DatabaseHelper(); // optional (offline cache)

  List<Bill>      _bills      = [];
  List<HoldOrder> _holdOrders = [];
  bool            _isOnline   = false;
  bool            _isLoading  = false;  // ✅ NEW: Loading state
  String?         _error      = null;   // ✅ NEW: Error message

  StreamSubscription? _billsSub;
  StreamSubscription? _holdsSub;

  List<Bill>      get bills      => _bills;
  List<HoldOrder> get holdOrders => _holdOrders;
  bool            get isOnline   => _isOnline;
  bool            get isLoading  => _isLoading;  // ✅ NEW: Getter for loading
  String?         get error      => _error;      // ✅ NEW: Getter for error

  // ── LOAD FROM FIREBASE ONLY ───────────────────────────
  Future<void> loadBills() async {
    try {
      _isLoading = true;  // ✅ Start loading
      _error = null;
      notifyListeners();
      
      await _connectFirebase();
      
      _isLoading = false;  // ✅ Done loading
      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadBills error: $e");
      _isLoading = false;
      _error = "Failed to load bills: $e";
      _isOnline = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _connectFirebase() async {
    try {
      // 🔥 Subscribe to the real-time streams IMMEDIATELY so data appears as
      // fast as Firestore can deliver it (cache-first, then server). We no
      // longer block on a 3-second connectivity ping before showing data.
      _billsSub?.cancel();
      _billsSub = FirebaseService.billsStream().listen((bills) {
        _bills = bills;
        _isLoading = false;  // ✅ Done loading first batch
        _error = null;
        _isOnline = true;

        // Cache locally for offline use — MOBILE ONLY. On web each insert
        // rewrites the whole bills list in IndexedDB, so doing it 200× per
        // realtime update froze the UI. Firestore already caches on web.
        if (!kIsWeb) {
          for (final bill in bills) {
            _db.insertBill(bill);
          }
        }

        debugPrint("✅ Bills loaded: ${bills.length} items");
        notifyListeners();
      }, onError: (e, stacktrace) {
        debugPrint("❌ Bills stream error: $e, Stack: $stacktrace");
        _isLoading = false;
        _error = "Stream error: $e";
        _isOnline = false;
        notifyListeners();
      });

      // 🔥 Real-time Hold Orders
      _holdsSub?.cancel();
      _holdsSub = FirebaseService.holdOrdersStream().listen((holds) {
        _holdOrders = holds;
        notifyListeners();
      });

      // Connectivity check runs in the BACKGROUND — it only updates the
      // online/offline banner and never delays the data above.
      FirebaseService.isOnline().then((online) {
        _isOnline = online;
        _error = online ? null : "You are offline. Using cached data.";
        notifyListeners();
      });
    } catch (e) {
      debugPrint("❌ _connectFirebase error: $e");
      _isOnline = false;
      notifyListeners();
    }
  }

  // ── ADD BILL ──────────────────────────────────────────
  Future<Bill> addBill(Bill bill) async {
    _bills.insert(0, bill);
    notifyListeners();

    try {
      await FirebaseService.saveBill(bill); // 🔥 direct Firebase
    } catch (e) {
      debugPrint("❌ Failed to save bill: $e");

      // Optional fallback
      await _db.insertBill(bill);
    }

    return bill;
  }

  // ── HOLD ORDER ────────────────────────────────────────
  Future<void> holdOrder(HoldOrder order) async {
    _holdOrders.insert(0, order);
    notifyListeners();

    try {
      await FirebaseService.saveHoldOrder(order);
    } catch (e) {
      debugPrint("❌ Hold save failed: $e");
      await _db.insertHoldOrder(order);
    }
  }

  Future<void> updateHoldOrder(HoldOrder order) async {
    final idx = _holdOrders.indexWhere((h) => h.id == order.id);
    if (idx != -1) _holdOrders[idx] = order;

    notifyListeners();

    try {
      await FirebaseService.saveHoldOrder(order);
    } catch (e) {
      debugPrint("❌ Hold update failed: $e");
    }
  }

  Future<void> deleteHoldOrder(String id) async {
    _holdOrders.removeWhere((h) => h.id == id);
    notifyListeners();

    try {
      await FirebaseService.deleteHoldOrder(id);
    } catch (e) {
      debugPrint("❌ Delete hold failed: $e");
    }
  }

  // ── SALES LOGIC (UNCHANGED) ───────────────────────────
  DailySales getSalesByDate(DateTime date) {
    final dateStr  = DateFormat('yyyy-MM-dd').format(date);

    final filtered = _bills.where(
      (b) => DateFormat('yyyy-MM-dd').format(b.createdAt) == dateStr,
    ).toList();

    return DailySales(
      date: dateStr,
      totalSales: filtered.fold(0, (s, b) => s + b.subtotal),
      totalOrders: filtered.length,
      cashSales: filtered
          .where((b) => b.paymentMode == PaymentMode.cash)
          .fold(0.0, (s, b) => s + b.subtotal),
      upiSales: filtered
          .where((b) => b.paymentMode == PaymentMode.upi)
          .fold(0.0, (s, b) => s + b.subtotal),
      cardSales: filtered
          .where((b) => b.paymentMode == PaymentMode.card)
          .fold(0.0, (s, b) => s + b.subtotal),
    );
  }

  DailySales getTodaysSales() => getSalesByDate(DateTime.now());

  List<Bill> getBillsByDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _bills.where(
      (b) => DateFormat('yyyy-MM-dd').format(b.createdAt) == dateStr,
    ).toList();
  }

  List<Bill> getRecentBills([int limit = 10]) =>
      _bills.take(limit).toList();

  @override
  void dispose() {
    _billsSub?.cancel();
    _holdsSub?.cancel();
    super.dispose();
  }
}