import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/bill.dart';
import '../theme/app_theme.dart';
import '../services/bluetooth_printer_service.dart';

class BillPreviewDialog extends StatefulWidget {
  final Bill bill;
  final VoidCallback onNewOrder;
  const BillPreviewDialog({
    super.key,
    required this.bill,
    required this.onNewOrder,
  });

  @override
  State<BillPreviewDialog> createState() => _BillPreviewDialogState();
}

class _BillPreviewDialogState extends State<BillPreviewDialog> {
  bool _isPrinting    = false;
  bool _btConnected   = false;
  String _printStatus = '';

  @override
  void initState() {
    super.initState();
    _checkAndPrint();
  }

  Future<void> _checkAndPrint() async {
    final connected = await BluetoothPrinterService.checkConnection();
    if (mounted) setState(() => _btConnected = connected);

    if (connected) {
      setState(() { _isPrinting = true; _printStatus = 'Bluetooth ne print hoto...'; });
      final ok = await BluetoothPrinterService.printBill(widget.bill);
      if (mounted) {
        setState(() {
          _isPrinting  = false;
          _printStatus = ok ? '✅ Bill print zali!' : '⚠️ BT print failed, PDF try kara';
        });
      }
    } else {
      if (mounted) {
        setState(() => _printStatus = '📄 PDF print dialog...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _pdfPrint();
        if (mounted) setState(() => _printStatus = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final grandTotal = bill.items.fold<double>(
    0,
    (sum, item) => sum + (item.quantity * item.product.price),
  );
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 660),
        child: Column(children: [

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Complete!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: AppTheme.success)),
                    if (_printStatus.isNotEmpty)
                      Text(_printStatus,
                        style: GoogleFonts.lato(
                          fontSize: 11, color: AppTheme.primary)),
                  ],
                ),
              ),
              if (_isPrinting)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary)),
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
            ]),
          ),

          // ── Printer status bar ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _btConnected
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.primary.withValues(alpha: 0.08),
            child: Row(children: [
              Icon(
                _btConnected ? Icons.bluetooth_connected : Icons.picture_as_pdf,
                size: 14,
                color: _btConnected ? AppTheme.success : AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                _btConnected
                    ? 'Bluetooth Printer Connected — Auto Print'
                    : 'Bluetooth nahi — PDF Print use hoto',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: _btConnected ? AppTheme.success : AppTheme.primary)),
            ]),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // ── Bill Content ─────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(children: [

                // ── LOGO ──────────────────────────────────────────────
                Center(child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      width: 2),
                    boxShadow: [BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10)],
                  ),
                  child: ClipOval(child: Image.asset(
                    'assets/images/image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primary,
                      child: const Icon(Icons.coffee,
                          color: Colors.white, size: 36)),
                  )),
                )),

                // ── CAFE NAME ─────────────────────────────────────────
                const SizedBox(height: 10),
                Text('The Cafe Elite',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppTheme.foreground)),
                const SizedBox(height: 2),
                Text('Fine Café & Bistro',
                  style: GoogleFonts.lato(
                    fontSize: 11, color: AppTheme.mutedForeground)),
                const SizedBox(height: 2),
                Text('TRUST THE TASTE',
                  style: GoogleFonts.lato(
                    fontSize: 9, color: AppTheme.primary,
                    letterSpacing: 2.5, fontWeight: FontWeight.w600)),

                // ── BILL NO + DATE ────────────────────────────────────
                const SizedBox(height: 12),
                const _Dashes(),
                const SizedBox(height: 10),
                _InfoRow('Bill No',
                  '#${bill.id.length > 8 ? bill.id.substring(bill.id.length - 8) : bill.id}'),
                const SizedBox(height: 4),
                _InfoRow('Date',
                  DateFormat('dd MMM yyyy  HH:mm').format(bill.createdAt)),

                // ── ITEMS ─────────────────────────────────────────────
                const SizedBox(height: 10),
                const _Dashes(),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('Item',
                    style: GoogleFonts.lato(fontSize: 10,
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w700))),
                  Text('Qty', style: GoogleFonts.lato(fontSize: 10,
                    color: AppTheme.mutedForeground,
                    fontWeight: FontWeight.w700)),
                  SizedBox(width: 70, child: Text('Amt',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.lato(fontSize: 10,
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 6),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 4),
                ...bill.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                          style: GoogleFonts.lato(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                        if (item.product.nameHindi != null)
                          Text(item.product.nameHindi!,
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              color: AppTheme.mutedForeground)),
                      ],
                    )),
                    Text('×${item.quantity}',
                      style: GoogleFonts.lato(
                        fontSize: 12, color: AppTheme.mutedForeground)),
                    SizedBox(width: 70, child: Text(
                      '₹${(item.quantity * item.product.price).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.lato(
                        fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                )),

                // ── SUBTOTAL (commented — show karyache nahi) ─────────
                // const SizedBox(height: 8),
                // const _Dashes(),
                // const SizedBox(height: 8),
                // _InfoRow('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}'),
                // const SizedBox(height: 4),
                // _InfoRow('CGST ($cgstRate%)', '₹${bill.cgst.toStringAsFixed(2)}'),
                // const SizedBox(height: 4),
                // _InfoRow('SGST ($sgstRate%)', '₹${bill.sgst.toStringAsFixed(2)}'),

                // ── TOTAL ─────────────────────────────────────────────
                const SizedBox(height: 8),
                const _Dashes(),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                   Text('₹${grandTotal.toStringAsFixed(2)}',  
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19, fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
                  ]),

                // ── PAYMENT ───────────────────────────────────────────
                const SizedBox(height: 8),
                const _Dashes(),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment',
                      style: GoogleFonts.lato(
                        fontSize: 12, color: AppTheme.mutedForeground)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _modeColor(bill.paymentMode)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _modeColor(bill.paymentMode)
                            .withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_modeIcon(bill.paymentMode), size: 13,
                            color: _modeColor(bill.paymentMode)),
                        const SizedBox(width: 5),
                        Text(bill.paymentMode.name.toUpperCase(),
                          style: GoogleFonts.lato(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: _modeColor(bill.paymentMode))),
                      ]),
                    ),
                  ]),

                // ── THANK YOU MSG ─────────────────────────────────────
                const SizedBox(height: 12),
                const _Dashes(),
                const SizedBox(height: 12),
                Text('Thank you for visiting! 🙏',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13, color: AppTheme.foreground,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('The Cafe Elite — Trust The Taste ☕',
                  style: GoogleFonts.lato(
                    fontSize: 10, color: AppTheme.mutedForeground)),

                // ── CONTACT ───────────────────────────────────────────
                const SizedBox(height: 12),
                const _Dashes(),
                const SizedBox(height: 10),
                Text('Sagar Katte',
                  style: GoogleFonts.lato(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: AppTheme.foreground)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.phone, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 5),
                  Text('8087553246',
                    style: GoogleFonts.lato(
                      fontSize: 12, color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // ── Action Buttons ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: Icon(
                      _btConnected ? Icons.bluetooth : Icons.print_outlined,
                      size: 16),
                    label: Text(
                      _isPrinting
                          ? 'Printing...'
                          : _btConnected ? 'BT Print' : 'PDF Print',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btConnected
                          ? AppTheme.primary : AppTheme.card,
                      foregroundColor: _btConnected
                          ? Colors.white : AppTheme.foreground,
                      side: _btConnected
                          ? null : BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareWhatsApp(context),
                    icon: const Icon(Icons.share, size: 16),
                    label: Text('WhatsApp', style: GoogleFonts.lato()),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onNewOrder,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('New Order',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Color    _modeColor(PaymentMode m) => switch(m) {
    PaymentMode.cash => Colors.green,
    PaymentMode.upi  => Colors.blue,
    PaymentMode.card => Colors.purple,
  };
  IconData _modeIcon(PaymentMode m) => switch(m) {
    PaymentMode.cash => Icons.money,
    PaymentMode.upi  => Icons.smartphone,
    PaymentMode.card => Icons.credit_card,
  };

  Future<void> _handlePrint() async {
    if (_btConnected) {
      setState(() => _isPrinting = true);
      final ok = await BluetoothPrinterService.printBill(widget.bill);
      if (mounted) {
        setState(() {
          _isPrinting  = false;
          _printStatus = ok ? '✅ Bill print zali!' : '⚠️ BT failed';
        });
        if (!ok) await _pdfPrint();
      }
    } else {
      await _pdfPrint();
    }
  }

  Future<void> _pdfPrint() async {
    final bytes = await _buildPdfBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final bytes = await _buildPdfBytes();
    final dir   = await getTemporaryDirectory();
    final file  = File('${dir.path}/bill_${widget.bill.id}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: '🧾 The Cafe Elite\n'
            'Total: ₹${widget.bill.grandTotal.toStringAsFixed(2)}\n'
            'Payment: ${widget.bill.paymentMode.name.toUpperCase()}',
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    final bill = widget.bill;
  final total = bill.items.fold<double>(
  0,
  (sum, item) => sum + (item.quantity * item.product.price),
);

// 👉 IMPORTANT: same value use everywhere
final grandTotal = total; 
    final doc  = pw.Document();

    pw.ImageProvider? logo;
    try {
      final d = await rootBundle.load('assets/images/cafe_logo.png');
      logo = pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) {}

    const brown = PdfColor.fromInt(0xFF2C1A0A);
    const gold  = PdfColor.fromInt(0xFFB8860B);
    const muted = PdfColor.fromInt(0xFF8A7A6A);
    const bdr   = PdfColor.fromInt(0xFFD4B483);

    pw.Widget dashes() => pw.Row(children: List.generate(28, (i) =>
      pw.Expanded(child: pw.Container(
        height: 1,
        color: i.isEven ? bdr : PdfColors.yellow800))));

    pw.Widget infoRow(String l, String v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l, style: pw.TextStyle(color: muted, fontSize: 10)),
          pw.Text(v, style: pw.TextStyle(
            color: brown, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ]));

    doc.addPage(pw.Page(
      pageFormat: const PdfPageFormat(
        80 * PdfPageFormat.mm, double.infinity,
        marginAll: 6 * PdfPageFormat.mm),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [

          // LOGO
          if (logo != null)
            pw.Container(
              width: 65, height: 65,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: const PdfColor.fromInt(0xFFF5F0E6),
                border: pw.Border.all(color: gold, width: 1.5)),
              child: pw.ClipOval(
                child: pw.Image(logo, width: 65, height: 65,
                    fit: pw.BoxFit.cover))),

          pw.SizedBox(height: 8),

          // CAFE NAME
          pw.Text('The Cafe Elite',
            style: pw.TextStyle(
              color: brown, fontWeight: pw.FontWeight.bold, fontSize: 17)),
          pw.SizedBox(height: 2),
          pw.Text('Fine Café & Bistro',
            style: pw.TextStyle(color: muted, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text('TRUST THE TASTE',
            style: pw.TextStyle(color: gold, fontSize: 8, letterSpacing: 2)),
          pw.SizedBox(height: 10),
          dashes(),
          pw.SizedBox(height: 8),

          // BILL NO + DATE
          infoRow('Bill No',
            '#${bill.id.length > 8 ? bill.id.substring(bill.id.length - 8) : bill.id}'),
          pw.SizedBox(height: 3),
          infoRow('Date',
            DateFormat('dd MMM yyyy  HH:mm').format(bill.createdAt)),

          pw.SizedBox(height: 8),
          dashes(),
          pw.SizedBox(height: 8),

          // ITEMS header
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Item',
              style: pw.TextStyle(color: muted, fontSize: 9,
                  fontWeight: pw.FontWeight.bold))),
            pw.Text('Qty',
              style: pw.TextStyle(color: muted, fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 55, child: pw.Text('Amt',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: muted, fontSize: 9,
                  fontWeight: pw.FontWeight.bold))),
          ]),
          pw.SizedBox(height: 4),
          pw.Divider(color: bdr, thickness: 0.5),
          pw.SizedBox(height: 4),

          // ITEMS rows
          ...bill.items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text(item.product.name,
                style: pw.TextStyle(color: brown, fontSize: 11,
                    fontWeight: pw.FontWeight.bold))),
              pw.Text('×${item.quantity}',
                style: pw.TextStyle(color: muted, fontSize: 11)),
              pw.SizedBox(width: 55, child:
               pw.Text(
                'Rs.${(item.quantity * item.product.price).toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(color: brown, fontSize: 11,
                    fontWeight: pw.FontWeight.bold))),
            ]))),

          pw.SizedBox(height: 8),
          dashes(),

          // SUBTOTAL (commented — show karyache nahi)
          // pw.SizedBox(height: 8),
          // infoRow('Subtotal', 'Rs.${bill.subtotal.toStringAsFixed(2)}'),
          // pw.SizedBox(height: 3),
          // infoRow('CGST ($cgstRate%)', 'Rs.${bill.cgst.toStringAsFixed(2)}'),
          // pw.SizedBox(height: 3),
          // infoRow('SGST ($sgstRate%)', 'Rs.${bill.sgst.toStringAsFixed(2)}'),
          // pw.SizedBox(height: 8),
          // dashes(),

          pw.SizedBox(height: 8),

          // TOTAL
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(
                color: brown, fontWeight: pw.FontWeight.bold, fontSize: 15)),
             pw.Text('₹${grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  color: gold, fontWeight: pw.FontWeight.bold, fontSize: 17)),
            ]),

          pw.SizedBox(height: 8),
          dashes(),
          pw.SizedBox(height: 8),

          // PAYMENT
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment',
                style: pw.TextStyle(color: muted, fontSize: 10)),
              pw.Text(bill.paymentMode.name.toUpperCase(),
                style: pw.TextStyle(
                  color: brown, fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ]),

          pw.SizedBox(height: 10),
          dashes(),
          pw.SizedBox(height: 10),

          // THANK YOU
          pw.Text('Thank you for visiting!',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: brown, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 3),
          pw.Text('The Cafe Elite — Trust The Taste',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: muted, fontSize: 9)),

          pw.SizedBox(height: 10),
          dashes(),
          pw.SizedBox(height: 8),

          // CONTACT
          pw.Text('Sagar Katte',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: brown, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 3),
          pw.Text('8087553246',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: gold, fontSize: 11)),
          pw.SizedBox(height: 10),
        ],
      ),
    ));

    return await doc.save();
  }
}

// ── Dashed line ───────────────────────────────────────────────────────────────
class _Dashes extends StatelessWidget {
  const _Dashes();
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(30, (i) => Expanded(
      child: Container(
        height: 1,
        color: i.isEven
            ? AppTheme.border.withValues(alpha: 0.8)
            : Colors.transparent))));
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String l, v;
  const _InfoRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: GoogleFonts.lato(
          fontSize: 12, color: AppTheme.mutedForeground)),
      Text(v, style: GoogleFonts.lato(
          fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
}
