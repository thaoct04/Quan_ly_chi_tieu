import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/animated_bar_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/transaction_tile.dart';
import 'scanner_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final allExpensesAsync = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: Color(0xFF0F766E),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý Chi tiêu OCR',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Theo dõi thông minh & Tự động quét',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu mẫu',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: () async {
              await ref.read(expenseProvider.notifier).resetToSampleData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã làm mới và nạp dữ liệu mẫu thành công!')),
                );
              }
            },
          ),
        ],
      ),
      body: allExpensesAsync.when(
        data: (allExpenses) {
          // Tính toán dữ liệu biến động chi tiêu theo ngày từ danh sách lọc
          final Map<String, double> dailySums = {};
          final sortedFiltered = List.of(filteredExpenses)..sort((a, b) => a.date.compareTo(b.date));

          for (var e in sortedFiltered) {
            final key = DateFormat('dd/MM').format(e.date);
            dailySums[key] = (dailySums[key] ?? 0) + e.amount;
          }

          final List<BarChartData> barData = dailySums.entries.map((entry) {
            return BarChartData(entry.key, entry.value);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(expenseProvider.notifier).loadExpenses();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Thẻ tổng quan tài chính
                const SummaryCard(),
                const SizedBox(height: 18),

                // 2. Bộ lọc thời gian (Tuần / Tháng / Năm / Tùy chỉnh)
                const TimeFilterBar(),
                const SizedBox(height: 18),

                // 3. Nút hành động nhanh (Quick Actions)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.camera_alt_rounded,
                        label: "Quét hóa đơn",
                        color: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScannerScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.analytics_rounded,
                        label: "Xem báo cáo",
                        color: const Color(0xFF3F51B5),
                        onTap: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(1); // Chuyển sang Tab Báo cáo
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 4. Biểu đồ biến động chi tiêu
                AnimatedBarChart(
                  title: "Biến động chi tiêu trong kỳ",
                  data: barData,
                ),
                const SizedBox(height: 24),

                // 5. Giao dịch gần đây
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Giao dịch gần đây",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (filteredExpenses.isNotEmpty && onNavigateTab != null)
                      TextButton(
                        onPressed: () => onNavigateTab!(3), // Chuyển tab Giao dịch
                        child: const Text("Xem tất cả"),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (filteredExpenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Chưa có giao dịch nào trong khoảng thời gian này.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScannerScreen()),
                            );
                          },
                          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                          label: const Text("Quét hóa đơn ngay"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredExpenses.take(5).map((e) => TransactionTile(
                    expense: e,
                    onDelete: () {
                      ref.read(expenseProvider.notifier).deleteExpense(e.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xóa giao dịch: ${e.merchantName}')),
                      );
                    },
                  )),
                const SizedBox(height: 60), // padding cho bottom navigation bar
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
