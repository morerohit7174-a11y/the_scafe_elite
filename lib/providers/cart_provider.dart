// lib/providers/cart_provider.dart
import 'package:cafe_elite/widgets/db_constants.dart';
import 'package:cafe_elite/widgets/pref_utils.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import '../models/bill.dart';
import '../models/constants.dart';
import '../data/database_helper.dart';

class CartProvider extends ChangeNotifier {
  final List<OrderItem> _items = [];
  PaymentMode _paymentMode = PaymentMode.cash;
  String      _tableName   = 'Walk-in';
  HoldOrder?  _editingHold;

  List<OrderItem> get items         => _items;
  PaymentMode     get paymentMode   => _paymentMode;
  String          get tableName     => _tableName;
  HoldOrder?      get editingHold   => _editingHold;
  bool            get isEditingHold => _editingHold != null;
  int             get itemCount     => _items.fold(0, (s, i) => s + i.quantity);
  double          get subtotal      => _items.fold(0, (s, i) => s + i.total);
  double          get cgst          => (subtotal * cgstRate) / 100;
  double          get sgst          => (subtotal * sgstRate) / 100;
  double          get totalTax      => cgst + sgst;
  double          get grandTotal    => subtotal + totalTax;

  void setPaymentMode(PaymentMode mode) { _paymentMode = mode; notifyListeners(); }
  void setTableName(String name)        { _tableName = name;   notifyListeners(); }

  void addItem(Product product) {
    final i = _items.indexWhere((x) => x.product.id == product.id);
    if (i != -1) _items[i].quantity++;
    else _items.add(OrderItem(product: product));
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final i = _items.indexWhere((x) => x.product.id == productId);
    if (i != -1) { _items[i].quantity++; notifyListeners(); }
  }

  void decrementQuantity(String productId) {
    final i = _items.indexWhere((x) => x.product.id == productId);
    if (i != -1) {
      if (_items[i].quantity == 1) _items.removeAt(i);
      else _items[i].quantity--;
      notifyListeners();
    }
  }

  void loadHoldOrder(HoldOrder hold) {
    _items.clear();
    _items.addAll(hold.items.map((i) => OrderItem(product: i.product, quantity: i.quantity)));
    _tableName   = hold.tableName;
    _editingHold = hold;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _paymentMode = PaymentMode.cash;
    _tableName   = 'Walk-in';
    _editingHold = null;
    notifyListeners();
  }

  Bill generateBill() => Bill(
    userId: SharedPreferenceUtils.getString(DatabaseConstants.userId),
    id: 'BILL-${DateTime.now().millisecondsSinceEpoch}',
    items: List.from(_items),
    subtotal: subtotal,
    cgst: cgst,
    sgst: sgst,
    totalTax: totalTax,
    grandTotal: grandTotal,
    paymentMode: _paymentMode,
    createdAt: DateTime.now(),
  );

  HoldOrder generateHoldOrder() => HoldOrder(
    id: _editingHold?.id ?? 'HOLD-${DateTime.now().millisecondsSinceEpoch}',
    tableName: _tableName,
    items: List.from(_items),
    subtotal: subtotal,
    grandTotal: grandTotal,
    createdAt: _editingHold?.createdAt ?? DateTime.now(),
  );
}
