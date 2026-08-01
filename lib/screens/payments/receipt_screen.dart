import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';

class ReceiptScreen extends StatelessWidget {
  final Payment payment;
  const ReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          IconButton(
            onPressed: () => _shareReceipt(context),
            icon: const Icon(Icons.share),
            tooltip: 'Copy receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [p.primary, p.indigo],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apartment,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PG Manager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'Payment Receipt',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Receipt Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
              ),
              const SizedBox(height: 8),
              _row(p, 'Receipt No', payment.receiptNumber ?? '#${payment.id}'),
              _row(p, 'Payment Date', formatDateTime(payment.paymentDate)),
              const SizedBox(height: 12),
              Text(
                'Tenant Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
              ),
              const SizedBox(height: 8),
              _row(p, 'Tenant', payment.tenantName),
              if (payment.roomNumber != null)
                _row(p, 'Room No', payment.roomNumber!),
              _row(
                p,
                'Payment Month',
                payment.paymentMonth.isEmpty
                    ? 'N/A'
                    : formatMonthLabel(payment.paymentMonth),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [p.success, p.success],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'AMOUNT PAID',
                      style: TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 1.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(payment.amount),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'PAID',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: p.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This is a computer-generated receipt and does not require a signature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final text = [
      'PG MANAGER - PAYMENT RECEIPT',
      'Receipt No: ${payment.receiptNumber ?? '#${payment.id}'}',
      'Date: ${formatDateTime(payment.paymentDate)}',
      'Tenant: ${payment.tenantName}',
      if (payment.roomNumber != null) 'Room: ${payment.roomNumber}',
      'Month: ${payment.paymentMonth}',
      'Amount: ${formatCurrency(payment.amount)}',
      'Status: PAID',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt copied to clipboard')),
    );
  }
}
