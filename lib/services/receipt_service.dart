import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item.dart';
import 'api_client.dart';

/// One line of a receipt as returned by `GET /api/orders/:id/receipt`.
class ReceiptLine {
  final String name;
  final String image;
  final int unitPriceCents;
  final int quantity;
  final int lineTotalCents;

  const ReceiptLine({
    required this.name,
    this.image = '',
    this.unitPriceCents = 0,
    this.quantity = 1,
    this.lineTotalCents = 0,
  });

  factory ReceiptLine.fromJson(Map<String, dynamic> json) => ReceiptLine(
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        unitPriceCents: (json['unitPriceCents'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        lineTotalCents: (json['lineTotalCents'] as num?)?.toInt() ?? 0,
      );
}

/// Client model of the server receipt payload (cents-based, ZMW).
class OrderReceipt {
  final String orderNumber;
  final String invoiceNo;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionId;
  final String referenceId;
  final String createdAt;
  final String deliveredAt;
  final String currency;
  final double vatPct;

  final String businessId;
  final String businessName;
  final String businessAddress;
  final String businessTpin;

  final String buyerName;
  final String buyerPhone;
  final String buyerTpin;

  final String deliveryAddress;
  final String deliveryMethod;
  final String riderName;
  final int deliveryFeeCents;

  final List<ReceiptLine> items;
  final int subtotalCents;
  final int vatCents;
  final int totalCents;

  const OrderReceipt({
    required this.orderNumber,
    this.invoiceNo = '',
    this.status = '',
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.transactionId = '',
    this.referenceId = '',
    this.createdAt = '',
    this.deliveredAt = '',
    this.currency = 'ZMW',
    this.vatPct = 16,
    this.businessId = '',
    this.businessName = '',
    this.businessAddress = '',
    this.businessTpin = '',
    this.buyerName = '',
    this.buyerPhone = '',
    this.buyerTpin = '',
    this.deliveryAddress = '',
    this.deliveryMethod = '',
    this.riderName = '',
    this.deliveryFeeCents = 0,
    this.items = const [],
    this.subtotalCents = 0,
    this.vatCents = 0,
    this.totalCents = 0,
  });

  factory OrderReceipt.fromJson(Map<String, dynamic> json) {
    final business = Map<String, dynamic>.from(
        (json['business'] as Map?) ?? const <String, dynamic>{});
    final buyer = Map<String, dynamic>.from(
        (json['buyer'] as Map?) ?? const <String, dynamic>{});
    final delivery = Map<String, dynamic>.from(
        (json['delivery'] as Map?) ?? const <String, dynamic>{});
    return OrderReceipt(
      orderNumber: '${json['orderNumber'] ?? ''}',
      invoiceNo: '${json['invoiceNo'] ?? ''}',
      status: '${json['status'] ?? ''}',
      paymentMethod: '${json['paymentMethod'] ?? ''}',
      paymentStatus: '${json['paymentStatus'] ?? ''}',
      transactionId: '${json['transactionId'] ?? ''}',
      referenceId: '${json['referenceId'] ?? ''}',
      createdAt: '${json['createdAt'] ?? ''}',
      deliveredAt: '${json['deliveredAt'] ?? ''}',
      currency: '${json['currency'] ?? 'ZMW'}',
      vatPct: (json['vatPct'] as num?)?.toDouble() ?? 16,
      businessId: '${business['id'] ?? ''}',
      businessName: '${business['name'] ?? ''}',
      businessAddress: '${business['address'] ?? ''}',
      businessTpin: '${business['tpin'] ?? ''}',
      buyerName: '${buyer['name'] ?? ''}',
      buyerPhone: '${buyer['phone'] ?? ''}',
      buyerTpin: '${buyer['tpin'] ?? ''}',
      deliveryAddress: '${delivery['address'] ?? ''}',
      deliveryMethod: '${delivery['method'] ?? ''}',
      riderName: '${delivery['riderName'] ?? ''}',
      deliveryFeeCents: (delivery['feeCents'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? [])
          .map((e) => ReceiptLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotalCents: (json['subtotalCents'] as num?)?.toInt() ?? 0,
      vatCents: (json['vatCents'] as num?)?.toInt() ?? 0,
      totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
    );
  }

  /// Local fallback used when the receipt endpoint is unreachable — built
  /// from the order the client already holds. The server remains the source
  /// of truth whenever it responds.
  factory OrderReceipt.fromOrder(
    Order order, {
    String businessName = '',
    String businessAddress = '',
    String businessTpin = '',
    String buyerName = '',
    double vatPct = 16,
  }) {
    final lines = order.items
        .map((item) => ReceiptLine(
              name: item.name,
              image: item.image,
              unitPriceCents: item.priceCents,
              quantity: item.quantity,
              lineTotalCents: item.priceCents * item.quantity,
            ))
        .toList();
    final itemsSubtotal =
        lines.fold<int>(0, (sum, line) => sum + line.lineTotalCents);
    final subtotal = order.subtotal > 0
        ? (order.subtotal * 100).round()
        : itemsSubtotal;
    final deliveryFee = (order.deliveryFee * 100).round();
    final total = order.totalCents > 0
        ? order.totalCents
        : (order.total * 100).round();
    final vat = total > 0 ? (total * vatPct / (100 + vatPct)).round() : 0;

    return OrderReceipt(
      orderNumber: order.id,
      invoiceNo: order.invoiceNo ?? '',
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      transactionId: order.transactionId ?? '',
      referenceId: order.referenceId ?? '',
      createdAt: order.date,
      deliveredAt: order.deliveredAt ?? '',
      currency: 'ZMW',
      vatPct: vatPct,
      businessName: businessName,
      businessAddress: businessAddress,
      businessTpin: businessTpin,
      buyerName: buyerName,
      buyerPhone: order.customerPhone ?? '',
      deliveryAddress: order.deliveryAddress,
      deliveryMethod: order.deliveryMethod,
      riderName: order.riderName ?? '',
      deliveryFeeCents: deliveryFee,
      items: lines,
      subtotalCents: subtotal,
      vatCents: vat,
      totalCents: total,
    );
  }
}

/// Fetches, renders and prints the branded order receipt PDF.
class ReceiptService {
  const ReceiptService._();

  static Future<OrderReceipt?> fetch(String orderId) async {
    final res = await ApiClient.instance.get('/api/orders/$orderId/receipt');
    final map = Map<String, dynamic>.from(res as Map);
    final receipt = (map['receipt'] as Map?) ?? map;
    return OrderReceipt.fromJson(Map<String, dynamic>.from(receipt));
  }

  static String money(int cents) {
    final value = (cents / 100).toStringAsFixed(2);
    final parts = value.split('.');
    final digits = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$digits.${parts[1]}';
  }

  static String _date(String value) => value.isEmpty ? '—' : value;

  static pw.Widget _labelValue(String label, String value) {
    final empty = value.trim().isEmpty || value.trim() == '—';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              empty ? '—' : value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalsRow(String label, String value,
      {bool bold = false, PdfColor? color, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List> buildPdf(OrderReceipt receipt) async {
    final doc = pw.Document();
    final items = receipt.items;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // ── Header ──────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0A0A0A),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Grand Elephants',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'MOVE WITH CONVICTION',
                  style: pw.TextStyle(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: PdfColor.fromInt(0xFFD4AF37),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'TAX RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                    color: PdfColors.grey300,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // ── Business + receipt meta ─────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      receipt.businessName.isEmpty
                          ? 'Grand Elephants'
                          : receipt.businessName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      receipt.businessAddress.isEmpty
                          ? 'Lusaka, Zambia'
                          : receipt.businessAddress,
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Business TPIN: ${receipt.businessTpin.isEmpty ? '—' : receipt.businessTpin}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _labelValue('Receipt No', receipt.orderNumber),
                    _labelValue('Invoice No', receipt.invoiceNo),
                    _labelValue('Date', _date(receipt.createdAt)),
                    if (receipt.deliveredAt.isNotEmpty)
                      _labelValue('Delivered', _date(receipt.deliveredAt)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // ── Buyer + delivery ────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED TO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _labelValue('Name',
                        receipt.buyerName.isEmpty ? 'Walk-in customer' : receipt.buyerName),
                    _labelValue('Phone', receipt.buyerPhone),
                    _labelValue('Buyer TPIN', receipt.buyerTpin),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DELIVERY',
                      style: pw.TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _labelValue('Method', receipt.deliveryMethod),
                    _labelValue(
                        'Rider', receipt.riderName.isEmpty ? '—' : receipt.riderName),
                    _labelValue(
                        'Address',
                        receipt.deliveryAddress.isEmpty
                            ? '—'
                            : receipt.deliveryAddress),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ── Line items ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3F4F6),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    'ITEM',
                    style: pw.TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'QTY',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'UNIT (ZMW)',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL (ZMW)',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 14),
              child: pw.Text(
                'No items recorded on this receipt.',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
              ),
            )
          else
            ...items.map(
              (line) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        line.name.isEmpty ? 'Item' : line.name,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        '${line.quantity}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        money(line.unitPriceCents),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        money(line.lineTotalCents),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.grey400, thickness: 1.2),
          pw.SizedBox(height: 8),

          // ── Totals ──────────────────────────────────────────────
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9FAFB),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                children: [
                  _totalsRow('Subtotal', money(receipt.subtotalCents)),
                  _totalsRow(
                    'VAT (${receipt.vatPct.toStringAsFixed(0)}%)',
                    money(receipt.vatCents),
                  ),
                  _totalsRow('Delivery fee', money(receipt.deliveryFeeCents)),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  _totalsRow(
                    'TOTAL (${receipt.currency})',
                    money(receipt.totalCents),
                    bold: true,
                    color: PdfColor.fromInt(0xFF0A0A0A),
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Payment ─────────────────────────────────────────────
          pw.Text(
            'PAYMENT',
            style: pw.TextStyle(
              fontSize: 8,
              letterSpacing: 2,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
            ),
          ),
          pw.SizedBox(height: 6),
          _labelValue('Method', receipt.paymentMethod),
          _labelValue('Payment status', receipt.paymentStatus),
          _labelValue('Transaction ID', receipt.transactionId),
          _labelValue('Reference', receipt.referenceId),
          _labelValue('Order status', receipt.status),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // ── Footer ──────────────────────────────────────────────
          pw.Text(
            'Thank you for shopping with Grand Elephants. '
            'Premium bags, carried with conviction.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This receipt was generated by the Grand Elephants app on '
            '${DateTime.now().toLocal()}. Keep it for your records. '
            'Prices are in Zambian Kwacha (ZMW).',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Opens the browser/OS print dialog with the receipt (works on web,
  /// Android, iOS and desktop).
  static Future<bool> print(OrderReceipt receipt) {
    return Printing.layoutPdf(onLayout: (_) => buildPdf(receipt));
  }

  /// Shares the receipt as a PDF file; returns false when the platform
  /// cannot share (caller surfaces a toast).
  static Future<bool> share(OrderReceipt receipt) async {
    final bytes = await buildPdf(receipt);
    return Printing.sharePdf(
      bytes: bytes,
      filename:
          'grand-elephants-receipt-${receipt.orderNumber.isEmpty ? 'receipt' : receipt.orderNumber}.pdf',
    );
  }
}
