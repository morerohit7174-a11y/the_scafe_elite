// lib/services/excel_export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';

class ExcelExportService {
  // ✅ Export daily sales report to Excel
  static Future<void> exportDailySalesReport({
    required List<Bill> bills,
    required DateTime date,
    required double totalSales,
    required int totalOrders,
    required double cashSales,
    required double upiSales,
    required double cardSales,
    required double totalTax,
  }) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Daily Report'];

      // ✅ Title
      int row = 0;
      final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      titleCell.value = TextCellValue('Daily Sales Report - ${DateFormat('dd MMM yyyy').format(date)}');
      titleCell.cellStyle = CellStyle(
        fontSize: 14,
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF8B6F47'),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      );

      // ✅ Summary Section (Row 2-8)
      row = 2;
      
      _addSummaryRow(sheet, row++, 'Total Sales', '₹${totalSales.toStringAsFixed(2)}', true);
      _addSummaryRow(sheet, row++, 'Total Orders', '$totalOrders', false);
      _addSummaryRow(sheet, row++, 'Total Tax', '₹${totalTax.toStringAsFixed(2)}', false);
      _addSummaryRow(sheet, row++, 'Cash Sales', '₹${cashSales.toStringAsFixed(2)}', false);
      _addSummaryRow(sheet, row++, 'UPI Sales', '₹${upiSales.toStringAsFixed(2)}', false);
      _addSummaryRow(sheet, row++, 'Card Sales', '₹${cardSales.toStringAsFixed(2)}', false);

      // ✅ Bills Details Section
      row += 2; // Add space
      final detailsHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      detailsHeader.value = TextCellValue('Bill Details');
      detailsHeader.cellStyle = CellStyle(fontSize: 12, bold: true);
      row++;

      // ✅ Table Headers
      final headers = ['Bill ID', 'Customer', 'Items', 'Subtotal', 'Tax', 'Total', 'Payment Mode', 'Time'];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          fontSize: 11,
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('FF8B6F47'),
          fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        );
      }

      // ✅ Bill Data Rows
      row++;
      for (final bill in bills) {
        int col = 0;
        _setCellValue(sheet, col++, row, bill.id.length > 8 ? bill.id.substring(bill.id.length - 8) : bill.id);
        _setCellValue(sheet, col++, row, bill.customerName ?? 'Walk-in');
        _setCellValue(sheet, col++, row, '${bill.items.length} items');
        _setCellValue(sheet, col++, row, '₹${bill.subtotal.toStringAsFixed(2)}');
        _setCellValue(sheet, col++, row, '₹${bill.totalTax.toStringAsFixed(2)}');
        _setCellValue(sheet, col++, row, '₹${bill.grandTotal.toStringAsFixed(2)}');
        _setCellValue(sheet, col++, row, bill.paymentMode.name.toUpperCase());
        _setCellValue(sheet, col++, row, DateFormat('HH:mm').format(bill.createdAt));
        row++;
      }

      // ✅ Save to file
      final fileName = 'Sales_Report_${DateFormat('ddMMyyyy').format(date)}.xlsx';
      final file = await _saveFile(excel, fileName);

      debugPrint('✅ Excel exported: ${file.path}');

      // ✅ Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Daily Sales Report - ${DateFormat('dd MMM yyyy').format(date)}',
        text: 'Total Sales: ₹${totalSales.toStringAsFixed(2)} | Orders: $totalOrders',
      );
    } catch (e) {
      debugPrint('❌ Excel export error: $e');
      rethrow;
    }
  }

  // ✅ Helper: Add summary row
  static void _addSummaryRow(
    Sheet sheet,
    int row,
    String label,
    String value,
    bool highlight,
  ) {
    final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    labelCell.value = TextCellValue(label);
    labelCell.cellStyle = CellStyle(
      fontSize: 11,
      bold: highlight,
      backgroundColorHex: highlight ? ExcelColor.fromHexString('FF8B6F47') : ExcelColor.fromHexString('FFFFF5E6'),
      fontColorHex: highlight ? ExcelColor.fromHexString('FFFFFFFF') : ExcelColor.fromHexString('FF1a1a1a'),
    );

    final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    valueCell.value = TextCellValue(value);
    valueCell.cellStyle = CellStyle(
      fontSize: 11,
      bold: highlight,
      backgroundColorHex: highlight ? ExcelColor.fromHexString('FF8B6F47') : ExcelColor.fromHexString('FFFFF5E6'),
      fontColorHex: highlight ? ExcelColor.fromHexString('FFFFFFFF') : ExcelColor.fromHexString('FF1a1a1a'),
    );
  }

  // ✅ Helper: Set cell value
  static void _setCellValue(Sheet sheet, int col, int row, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value.toString());
    cell.cellStyle = CellStyle(fontSize: 10);
  }

  // ✅ Save Excel file to downloads
  static Future<File> _saveFile(Excel excel, String fileName) async {
    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final String dir = (await getDownloadsDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path;
    final String filePath = '$dir/$fileName';

    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }
}
