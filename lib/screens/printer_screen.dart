// lib/screens/printer_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
  import '../services/bluetooth_printer_service.dart';
import '../theme/app_theme.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});
  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning    = false;
  bool _isConnecting  = false;
  bool _isConnected   = false;
  String _statusMsg   = 'Printer connect karanya sathi Scan kara';
  String? _connectedName;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final conn = await BluetoothPrinterService.checkConnection();
    if (mounted) {
      setState(() {
        _isConnected  = conn;
        _connectedName = BluetoothPrinterService.connectedPrinter?.name;
        _statusMsg    = conn
            ? '✅ Connected: $_connectedName'
            : 'Printer connect karanya sathi Scan kara';
      });
    }
  }

  Future<void> _scan() async {
    setState(() { _isScanning = true; _statusMsg = 'Scanning...'; });
    final devices = await BluetoothPrinterService.getPairedDevices();
    setState(() {
      _devices   = devices;
      _isScanning = false;
      _statusMsg  = devices.isEmpty
          ? '❌ Kona printer sahapat nahi. Phone Bluetooth settings madhe pair kara.'
          : '${devices.length} printer sahapat zala';
    });
  }

  Future<void> _connect(BluetoothInfo device) async {
    setState(() { _isConnecting = true; _statusMsg = '${device.name} la connect hoto...'; });
    final ok = await BluetoothPrinterService.connect(device);
    setState(() {
      _isConnecting  = false;
      _isConnected   = ok;
      _connectedName = ok ? device.name : null;
      _statusMsg     = ok
          ? '✅ Connected: ${device.name}'
          : '❌ Connect zala nahi. Printer ON ahe ka check kara.';
    });
  }

  Future<void> _disconnect() async {
    await BluetoothPrinterService.disconnect();
    setState(() {
      _isConnected   = false;
      _connectedName = null;
      _statusMsg     = 'Disconnected';
    });
  }

  Future<void> _testPrint() async {
    final ok = await BluetoothPrinterService.testPrint();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ Test print successful!' : '❌ Print failed'),
      backgroundColor: ok ? AppTheme.success : AppTheme.destructive,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.card,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, "/dashboard");
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Printer Settings',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Bluetooth Thermal Printer',
                        style: GoogleFonts.lato(
                          fontSize: 12, color: AppTheme.mutedForeground)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isConnected
                              ? AppTheme.success : AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isConnected
                                ? Icons.check_circle : Icons.bluetooth_disabled,
                            color: _isConnected
                                ? AppTheme.success : AppTheme.mutedForeground,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_statusMsg,
                              style: GoogleFonts.lato(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scan button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scan,
                        icon: _isScanning
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.bluetooth_searching),
                        label: Text(_isScanning ? 'Scanning...' : 'Paired Printers Scan Kara'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Device list
                    if (_devices.isNotEmpty) ...[
                      Text('Sahapat Zaleyle Printers',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ..._devices.map((device) {
                        final isThisConnected =
                            _isConnected && _connectedName == device.name;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isThisConnected
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isThisConnected
                                  ? AppTheme.success : AppTheme.border,
                              width: isThisConnected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.print,
                                color: isThisConnected
                                    ? AppTheme.success : AppTheme.mutedForeground,
                                size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(device.name,
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                    Text(device.macAdress,
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: AppTheme.mutedForeground)),
                                  ],
                                ),
                              ),
                              if (isThisConnected)
                                OutlinedButton(
                                  onPressed: _disconnect,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.destructive,
                                    side: const BorderSide(
                                        color: AppTheme.destructive),
                                  ),
                                  child: const Text('Disconnect'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _isConnecting
                                      ? null : () => _connect(device),
                                  child: _isConnecting
                                      ? const SizedBox(width: 16, height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                      : const Text('Connect'),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Test print
                    if (_isConnected) ...[
                      const SizedBox(height: 20),
                      Text('Test Print',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Test Print Kara'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tips_and_updates,
                                  color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text('Setup Kasa Karaycha',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _tip('1. Thermal printer ON kara'),
                          _tip('2. Phone → Settings → Bluetooth madhe printer pair kara'),
                          _tip('3. Ithe "Scan" tap kara'),
                          _tip('4. Tumcha printer select karun "Connect" tap kara'),
                          _tip('5. Test print karun check kara'),
                          _tip('✅ Aata order complete kelyas automatic print hoel!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
      style: GoogleFonts.lato(fontSize: 13, color: AppTheme.foreground)),
  );
}
