import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../data/default_products.dart';

class ProductsProvider extends ChangeNotifier {

static const String env =
     // Live -
      String.fromEnvironment('ENV', defaultValue: 'cafe_elite');

      // UAT-
      //  String.fromEnvironment('ENV', defaultValue: 'uat_cafe_elite');

      

  static final _col = FirebaseFirestore.instance
      .collection(env)
      .doc('data')
      .collection('products');

  List<Product> _products = [];
  List<Product> get products => _products;
  List<Product> get availableProducts =>
      _products.where((p) => p.isAvailable).toList();

  void listenToProducts() {
    _col.snapshots().listen((snap) {
      if (snap.docs.isEmpty) {
        _uploadDefaults();
      } else {
        _products = snap.docs
            .map((d) => Product.fromJson(d.data()))
            .toList();
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Products stream error: $e');
    });
  }

  Future<void> _uploadDefaults() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final p in defaultProducts) {
      batch.set(_col.doc(p.id), p.toJson());
    }
    await batch.commit();
  }

  Future<void> addProduct(Product product) async {
    try {
      await _col.doc(product.id).set(product.toJson());
    } catch (e) {
      debugPrint('addProduct error: $e');
    }
  }

  Future<void> updateProduct(String id, Product updated) async {
    try {
      await _col.doc(id).update(updated.toJson());
    } catch (e) {
      debugPrint('updateProduct error: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      debugPrint('deleteProduct error: $e');
    }
  }

  Future<void> toggleAvailability(String id) async {
    try {
      final p = _products.firstWhere((p) => p.id == id);
      await _col.doc(id).update({'isAvailable': !p.isAvailable});
    } catch (e) {
      debugPrint('toggleAvailability error: $e');
    }
  }
}