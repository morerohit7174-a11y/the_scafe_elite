// lib/services/bluetooth_printer_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/bill.dart';
import '../models/constants.dart';

class BluetoothPrinterService {
  static BluetoothInfo? _connectedPrinter;
  static BluetoothInfo? get connectedPrinter => _connectedPrinter;
  static bool get isConnected => !kIsWeb && _connectedPrinter != null;

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  static Future<List<BluetoothInfo>> getPairedDevices() async {
    if (kIsWeb) return [];
    await requestPermissions();
    try {
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) return [];
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> connect(BluetoothInfo device) async {
    if (kIsWeb) return false;
    try {
      final result = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress);
      if (result) _connectedPrinter = device;
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    if (kIsWeb) return;
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedPrinter = null;
    } catch (_) {}
  }

  static Future<bool> checkConnection() async {
    if (kIsWeb) return false;
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> printBill(Bill bill) async {
    if (kIsWeb) return false;
    final connected = await checkConnection();
    if (!connected) return false;

    try {
      List<int> bytes = [];
      final grandTotal = bill.items.fold<double>(
        0,
        (sum, item) => sum + (item.quantity * item.product.price),
      );

      void ln(String text) {
        bytes.addAll(text.codeUnits);
        bytes.add(10);
      }

      void separator() => ln('--------------------------------');
      void row(String left, String right) {
        final space = 32 - left.length - right.length;
        if (space > 0) {
          ln(left + ' ' * space + right);
        } else {
          ln(left);
          ln(' ' * (32 - right.length) + right);
        }
      }

      bytes.addAll([0x1B, 0x40]); // Reset printer

      // Center align
      bytes.addAll([0x1B, 0x61, 0x01]);

      bytes.addAll([0x1D, 0x21, 0x11]); // Double height & width
      bytes.addAll([0x1B, 0x45, 0x01]);
      ln('THE CAFE ELITE');

      ln('');
      bytes.addAll([0x1D, 0x21, 0x00]);
      bytes.addAll([0x1B, 0x45, 0x00]);
      ln('Fine Cafe & Bistro');
      ln('TRUST THE TASTE');
      ln('');

      bytes.addAll([0x1B, 0x61, 0x00]);

      separator();

      final billNo = bill.id.length > 12
          ? bill.id.substring(bill.id.length - 12)
          : bill.id;
      ln('Bill No : $billNo');
      ln('Date    : ${_fmt(bill.createdAt)}');
      ln('Payment : ${bill.paymentMode.name.toUpperCase()}');
      separator();

      // Items header
      ln('Item           Qty Price Amount');
      separator();

      for (final item in bill.items) {
        final fullName = item.product.name;

        // Split name + size
        String name = fullName;
        String size = '';

        final parts = fullName.split(' ');
        if (parts.length > 1) {
          size = parts.last;
          name = parts.sublist(0, parts.length - 1).join(' ');
        }

        if (name.length > 14) name = name.substring(0, 14);

        final qty    = item.quantity.toString();
        final price  = item.product.price.toStringAsFixed(0);
        final amount = (item.quantity * item.product.price).toStringAsFixed(2);

        final line = name.padRight(14) +
            qty.padLeft(3) +
            price.padLeft(6) +
            amount.padLeft(9);

        ln(line);

        if (size.isNotEmpty) ln('  $size');
      }

      separator();
      bytes.addAll([0x1B, 0x45, 0x01]); // bold
      ln('TOTAL'.padRight(20) + grandTotal.toStringAsFixed(2).padLeft(12));
      bytes.addAll([0x1B, 0x45, 0x00]);
      separator();

      bytes.addAll([0x1B, 0x61, 0x01]); // center
      ln('Above TVS Showroom Dahiwadi');
      ln('Maharashtra - 415508');
      separator();
      ln('Sagar Katte  8087553246');
      ln('Thank You! Visit Again');

      bytes.addAll([0x1B, 0x61, 0x00]);
      bytes.addAll([0x0A, 0x0A, 0x0A]);
      bytes.addAll([0x1D, 0x56, 0x41, 0x10]); // cut

      await PrintBluetoothThermal.writeBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> testPrint() async {
    if (kIsWeb) return false;
    final connected = await checkConnection();
    if (!connected) return false;
    try {
      List<int> bytes = [];
      bytes.addAll([0x1B, 0x40, 0x1B, 0x61, 0x01]);
      bytes.addAll('--- TEST PRINT ---\n'.codeUnits);
      bytes.addAll('THE CAFE ELITE\n'.codeUnits);
      bytes.addAll('Printer OK!\n'.codeUnits);
      bytes.addAll([0x1B, 0x61, 0x00, 0x0A, 0x0A, 0x0A]);
      await PrintBluetoothThermal.writeBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}