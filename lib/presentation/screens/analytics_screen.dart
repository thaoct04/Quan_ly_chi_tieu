import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_utils.dart';
import '../providers/expense_provider.dart';
import '../widgets/animated_bar_chart.dart';
import '../widgets/animated_pie_chart.dart';
import '../widgets/time_filter_bar.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = ref.watch(filteredExpensesProvider);

    // Tính toán số liệu thống kê
    final double totalAmount = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final int count = filteredExpenses.length;
    final double maxExpense = filteredExpenses.isEmpty
        ? 0.0
        : filteredExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    // 1. Phân bổ theo Cửa hàng / Đơn vị
    final Map<String, double> merchantSums = {};
    for (var e in filteredExpenses) {
      merchantSums[e.merchantName] = (merchantSums[e.merchantName] ?? 0) + e.amount;
    }

    final sortedMerchants = merchantSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = [
      const Color(0xFF0F766E), // Teal
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFE91E63), // Pink
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFF795548), // Brown
    ];

    final List<PieChartData> merchantPieData = sortedMerchants.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      return PieChartData(
        e.key,
        e.value,
        chartColors[idx % chartColors.length],
      );
    }).toList();

    // 2. Phân bổ theo Danh mục
    final Map<String, double> categorySums = {};
    for (var e in filteredExpenses) {
      categorySums[e.category] = (categorySums[e.category] ?? 0) + e.amount;
    }

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartData> categoryPieData = sortedCategories.map((e) {
      final cat = CategoryConstants.getCategory(e.key);
      return PieChartData(e.key, e.value, cat.color);
    }).toList();

    // 3. Biến động chi tiêu theo thời gian
    final Map<String, double> timeSums = {};
    final sortedByDate = List.of(filteredExpenses)..sort((a, b) => a.date.compareTo(b.date));
    for (var e in sortedByDate) {
      final key = DateFormat('dd/MM').format(e.date);
      timeSums[key] = (timeSums[key] ?? 0) + e.amount;
    }

    final List<BarChartData> barData = timeSums.entries.map((entry) {
      return BarChartData(entry.key, entry.value);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Báo cáo & Phân tích Chi tiêu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Bộ lọc thời gian
          const TimeFilterBar(),
          const SizedBox(height: 16),

          // 2. Thẻ tóm tắt các chỉ số chính (Key Metrics)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    label: "Tổng chi",
                    value: CurrencyUtils.formatCompactVND(totalAmount),
                    color: const Color(0xFF0F766E),
                    icon: Icons.payments_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildMetricItem(
                    label: "Số hóa đơn",
                    value: '$count phiếu',
                    color: const Color(0xFF3F51B5),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildMetricItem(
                    label: "Lớn nhất",
                    value: CurrencyUtils.formatCompactVND(maxExpense),
                    color: const Color(0xFFE11D48),
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Biểu đồ biến động chi tiêu theo thời gian
          AnimatedBarChart(
            title: "Biến động chi tiêu theo ngày",
            data: barData,
            primaryColor: const Color(0xFF0F766E),
            secondaryColor: const Color(0xFF14B8A6),
          ),
          const SizedBox(height: 24),

          // 4. Tab chuyển đổi giữa Cửa hàng và Danh mục
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF0F766E),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Theo Cửa hàng / Đơn vị"),
                Tab(text: "Theo Danh mục"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Nội dung biểu đồ tròn theo Tab
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return AnimatedPieChart(
                  title: "Tỷ lệ chi tiêu theo Đơn vị / Cửa hàng",
                  data: merchantPieData,
                );
              } else {
                return AnimatedPieChart(
                  title: "Tỷ lệ chi tiêu theo Danh mục",
                  data: categoryPieData,
                );
              }
            },
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
