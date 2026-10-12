import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Gom nhóm giao dịch theo Ngày
    final Map<String, List<Expense>> grouped = {};
    for (var e in filteredExpenses) {
      final dateKey = DateFormat('dd/MM/yyyy').format(e.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(e);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lịch sử Giao dịch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // Thanh tìm kiếm
                TextField(
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cửa hàng, học phí, nội dung...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Danh mục Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: const Text('Tất cả danh mục'),
                          selected: selectedCategory == null,
                          onSelected: (_) {
                            ref.read(categoryFilterProvider.notifier).state = null;
                          },
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: selectedCategory == null ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ),
                      ),
                      ...CategoryConstants.categories.map((cat) {
                        final isSelected = selectedCategory == cat.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(categoryFilterProvider.notifier).state = isSelected ? null : cat.name;
                            },
                            selectedColor: cat.color,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bộ lọc thời gian
                const TimeFilterBar(),
              ],
            ),
          ),

          // Danh sách giao dịch
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "Không tìm thấy giao dịch nào phù hợp",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final items = grouped[dateKey]!;
                      final dayTotal = items.fold(0.0, (sum, item) => sum + item.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.formatVND(dayTotal),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((e) => TransactionTile(
                                expense: e,
                                onDelete: () {
                                  ref.read(expenseProvider.notifier).deleteExpense(e.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã xóa giao dịch: ${e.merchantName}')),
                                  );
                                },
                              )),
                          const SizedBox(height: 6),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
