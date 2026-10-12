import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/expense_model.dart';

class TransactionTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.expense,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryConstants.getCategory(expense.category);
    final paymentIcon = CategoryConstants.getPaymentIcon(expense.paymentMethod);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap ?? () => _showDetailBottomSheet(context),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            category.icon,
            color: category.color,
            size: 24,
          ),
        ),
        title: Text(
          expense.merchantName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(expense.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              if (expense.paymentMethod != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(paymentIcon, size: 12, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        expense.paymentMethod!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-${CurrencyUtils.formatVND(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFFE11D48), // Rose Red
              ),
            ),
            const SizedBox(height: 2),
            Text(
              expense.category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context) {
    final category = CategoryConstants.getCategory(expense.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(category.icon, color: category.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category,
                        style: TextStyle(
                          color: category.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        expense.merchantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Số tiền thanh toán", CurrencyUtils.formatVND(expense.amount), isHighlight: true),
                  const Divider(height: 16),
                  _buildDetailRow("Ngày giao dịch", DateFormat('dd/MM/yyyy HH:mm').format(expense.date)),
                  const Divider(height: 16),
                  _buildDetailRow("Phương thức", expense.paymentMethod ?? 'Chưa xác định'),
                  if (expense.invoiceCode != null && expense.invoiceCode!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow("Mã / Số hóa đơn", expense.invoiceCode!),
                  ],
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow("Nội dung thu/chi", expense.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (onDelete != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete!();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  label: const Text("Xóa giao dịch này", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 13,
            color: isHighlight ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
