import 'package:cafe_elite/widgets/db_constants.dart';
import 'package:cafe_elite/widgets/pref_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/order_item.dart';
import '../data/database_helper.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

 static const String env =
     // UAT -
      // String.fromEnvironment('ENV', defaultValue: 'uat_cafe_elite');

      // Live -

       String.fromEnvironment('ENV', defaultValue: 'cafe_elite');
  

  // ── Collections ───────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get _bills =>
      _db.collection(env).doc('data').collection('bills');

  static CollectionReference<Map<String, dynamic>> get _holds =>
      _db.collection(env).doc('data').collection('hold_orders');

   static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(env).doc('data').collection('users');


   


  // ── SAVE BILL ─────────────────────────────────────────
  static Future<void> saveBill(Bill bill) async {
    try {
      final userId =
          SharedPreferenceUtils.getString(DatabaseConstants.userId);

      if (userId.isEmpty) {
        debugPrint("❌ userId missing, cannot save bill");
        return;
      }

      await _bills.doc(bill.id).set({
        'userId': userId,
        'id': bill.id,
        'items': bill.items.map((i) => i.toJson()).toList(),
        'subtotal': bill.subtotal,
        'cgst': bill.cgst,
        'sgst': bill.sgst,
        'totalTax': bill.totalTax,
        'grandTotal': bill.grandTotal,
        'paymentMode': bill.paymentMode.name,
        'createdAt': Timestamp.fromDate(bill.createdAt),
        'customerName': bill.customerName,
        'customerPhone': bill.customerPhone,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Bill saved: ${bill.id}");
    } catch (e) {
      debugPrint('❌ Firebase saveBill error: $e');
    }
  }

  // ── GET USER ROLE ─────────────────────────────────────
  static Future<String> getUserRole() async {
    try {
      final userId =
          SharedPreferenceUtils.getString(DatabaseConstants.userId);
      print(  "Fetching role for userId: $userId");
      
      // ✅ Proper empty check
      if (userId.isEmpty) {
        debugPrint("⚠️ userId is empty, returning 'staff'");
        return 'staff';
      }

      final doc = await _users.doc(userId).get();
      final data = doc.data();
      print(  "User doc data: $data");
      if (data == null) {
        debugPrint("⚠️ User doc not found");
        return 'staff';
      }

      return data['role'] ?? 'staff';
    } catch (e) {
      debugPrint("❌ getUserRole error: $e");
      return 'staff';
    }
  }

  // ── GET BILLS (ONE TIME) ──────────────────────────────
  static Future<List<Bill>> getBills() async {
    try {
      final userId =
          SharedPreferenceUtils.getString(DatabaseConstants.userId);

      final role = await getUserRole();

      Query<Map<String, dynamic>> query = _bills
          .orderBy('timestamp', descending: true)
          .limit(500);

      if (role != 'admin') {
        query = query.where('userId', isEqualTo: userId);
      }

      final snap = await query.get();
  
      return snap.docs.map((doc) {
        final m = doc.data();

        if (m == null) return null;

        try {
          return _mapToBill(m, doc.id);
        } catch (e) {
          debugPrint("❌ Error parsing bill ${doc.id}: $e");
          return null;
        }
      }).whereType<Bill>().toList();
    } catch (e) {
      debugPrint('❌ Firebase getBills error: $e');
      return [];
    }
  }

  // ── REAL-TIME BILLS STREAM ────────────────────────────
  static Stream<List<Bill>> billsStream() async* {
  final userId =
      SharedPreferenceUtils.getString(DatabaseConstants.userId);

  // ✅ Null/empty check - return empty stream if not authenticated
  if (userId.isEmpty) {
    debugPrint("⚠️ userId is empty, returning empty bills stream");
    yield [];
    return;
  }

  final role = await getUserRole();

  Query<Map<String, dynamic>> query;

  print(  "Setting up bills stream for userId: $userId with role: $role");

  if (role == 'admin') {
    query = _bills
        .orderBy('timestamp', descending: true)
        .limit(200);
  } else {
    query = _bills
        .where('userId', isEqualTo: userId) // ✅ MUST FIRST
        .orderBy('timestamp', descending: true)
        .limit(200);
  }

  print("Listening with query: ${query.parameters}");

  yield* query.snapshots().map((snap) {
    return snap.docs.map((doc) {
      final m = doc.data();

      if (m == null) return null;

      try {
        final bill = _mapToBill(m, doc.id);

        print("✅ ${bill.id} | ${bill.userId} | ₹${bill.grandTotal}");

        return bill;
      } catch (e, stack) {
        debugPrint("❌ Error parsing bill ${doc.id}: $e,stack: $stack");
        return null;
      }
    }).whereType<Bill>().toList();
  });
}

  // ── HOLD ORDERS ───────────────────────────────────────
  static Future<void> saveHoldOrder(HoldOrder order) async {
    try {
      await _holds.doc(order.id).set({
        'id': order.id,
        'tableName': order.tableName,
        'items': order.items.map((i) => i.toJson()).toList(),
        'subtotal': order.subtotal,
        'grandTotal': order.grandTotal,
        'createdAt': order.createdAt.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ saveHoldOrder error: $e');
    }
  }

  static Future<void> deleteHoldOrder(String id) async {
    try {
      await _holds.doc(id).delete();
    } catch (e) {
      debugPrint('❌ deleteHoldOrder error: $e');
    }
  }

  static Stream<List<HoldOrder>> holdOrdersStream() {
    return _holds
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final m = doc.data();

        if (m == null) return null;

        try {
          return HoldOrder(
            id: m['id'] ?? doc.id,
            tableName: m['tableName'] ?? '',
            items: (m['items'] as List? ?? [])
                .map((i) =>
                    OrderItem.fromJson(i as Map<String, dynamic>))
                .toList(),
            subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
            grandTotal:
                (m['grandTotal'] as num?)?.toDouble() ?? 0,
            createdAt: DateTime.tryParse(m['createdAt'] ?? '') ??
                DateTime.now(),
          );
        } catch (e) {
          debugPrint("❌ Hold parse error: $e");
          return null;
        }
      }).whereType<HoldOrder>().toList();
    });
  }

  // ── COMMON BILL MAPPER (REUSABLE) ─────────────────────
  static Bill _mapToBill(Map<String, dynamic> m, String docId) {
  DateTime createdAt;

  final rawDate = m['createdAt'];

  if (rawDate is Timestamp) {
    createdAt = rawDate.toDate(); // ✅ correct
  } else if (rawDate is String) {
    createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
  } else {
    createdAt = DateTime.now();
  }

  return Bill(
    userId: m['userId'] ?? '',
    id: m['id'] ?? docId,
    items: (m['items'] as List? ?? [])
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
    cgst: (m['cgst'] as num?)?.toDouble() ?? 0,
    sgst: (m['sgst'] as num?)?.toDouble() ?? 0,
    totalTax: (m['totalTax'] as num?)?.toDouble() ?? 0,
    grandTotal: (m['grandTotal'] as num?)?.toDouble() ?? 0,
    paymentMode:
        PaymentMode.values.byName(m['paymentMode'] ?? 'cash'),
    createdAt: createdAt, // ✅ fixed
    customerName: m['customerName'],
    customerPhone: m['customerPhone'],
  );
}

  // ── INTERNET CHECK ────────────────────────────────────
  static Future<bool> isOnline() async {
    try {
      await _db
          .collection('ping')
          .doc('test')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));

      return true;
    } catch (_) {
      return false;
    }
  }
}