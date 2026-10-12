import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/expense_model.dart';

enum TimeFilterOption {
  week('Tuần này'),
  month('Tháng này'),
  year('Năm nay'),
  all('Tất cả'),
  custom('Tùy chỉnh');

  final String label;
  const TimeFilterOption(this.label);
}

class BudgetStatus {
  final double monthlyBudget;
  final double totalSpent;
  final double remaining;
  final double percentage;

  BudgetStatus({
    required this.monthlyBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentage,
  });
}

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [ExpenseSchema],
    directory: dir.path,
  );
});

// Bộ lọc thời gian
final timeFilterProvider = StateProvider<TimeFilterOption>((ref) => TimeFilterOption.month);
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Bộ lọc tìm kiếm & danh mục
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// Ngân sách hàng tháng (Mặc định 20.000.000 ₫)
final monthlyBudgetProvider = StateProvider<double>((ref) => 20000000.0);

final expenseProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpenseNotifier(ref);
});

class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;

  ExpenseNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final isar = await ref.read(isarProvider.future);
      final expenses = await isar.expenses.where().sortByDateDesc().findAll();
      
      // Nếu chưa có dữ liệu, tự động thêm một số giao dịch mẫu (bao gồm hóa đơn VKU mẫu)
      if (expenses.isEmpty) {
        await _seedInitialData(isar);
        final refreshed = await isar.expenses.where().sortByDateDesc().findAll();
        state = AsyncValue.data(refreshed);
      } else {
        state = AsyncValue.data(expenses);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _seedInitialData(Isar isar) async {
    final sampleExpenses = [
      Expense()
        ..merchantName = 'TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN VÀ TRUYỀN THÔNG VIỆT - HÀN'
        ..amount = 12706000.0
        ..date = DateTime(2026, 9, 14)
        ..category = 'Học phí & Giáo dục'
        ..paymentMethod = 'Chuyển khoản'
        ..note = 'Học phí học kỳ 1 năm học 2026-2027'
        ..invoiceCode = '2C26THP / 00008696',
      Expense()
        ..merchantName = 'Siêu thị Co.opmart Đà Nẵng'
        ..amount = 850000.0
        ..date = DateTime.now().subtract(const Duration(days: 1))
        ..category = 'Mua sắm'
        ..paymentMethod = 'Thẻ tín dụng / Ghi nợ'
        ..note = 'Mua thực phẩm tuần',
      Expense()
        ..merchantName = 'Highlands Coffee'
        ..amount = 125000.0
        ..date = DateTime.now().subtract(const Duration(days: 2))
        ..category = 'Ăn uống'
        ..paymentMethod = 'Ví điện tử'
        ..note = 'Cà phê họp nhóm',
      Expense()
        ..merchantName = 'Cây xăng Petrolimex Số 12'
        ..amount = 90000.0
        ..date = DateTime.now().subtract(const Duration(days: 3))
        ..category = 'Di chuyển'
        ..paymentMethod = 'Tiền mặt'
        ..note = 'Đổ xăng xe máy',
      Expense()
        ..merchantName = 'Điện lực EVN Miền Trung'
        ..amount = 620000.0
        ..date = DateTime.now().subtract(const Duration(days: 5))
        ..category = 'Hóa đơn & Dịch vụ'
        ..paymentMethod = 'Chuyển khoản'
        ..note = 'Tiền điện tháng trước',
    ];

    await isar.writeTxn(() async {
      for (var exp in sampleExpenses) {
        await isar.expenses.put(exp);
      }
    });
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.expenses.put(expense);
      });
      final expenses = await isar.expenses.where().sortByDateDesc().findAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.expenses.put(expense);
      });
      final expenses = await isar.expenses.where().sortByDateDesc().findAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.expenses.delete(id);
      });
      final expenses = await isar.expenses.where().sortByDateDesc().findAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetToSampleData() async {
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.expenses.clear();
      });
      await _seedInitialData(isar);
      final expenses = await isar.expenses.where().sortByDateDesc().findAll();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Lọc danh sách giao dịch theo thời gian, danh mục và từ khóa tìm kiếm
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expenseProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final categoryFilter = ref.watch(categoryFilterProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = DateTime.now();

      return expenses.where((e) {
        // Lọc theo thời gian
        bool matchesTime = true;
        switch (timeFilter) {
          case TimeFilterOption.week:
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
            final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            matchesTime = (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) &&
                          (e.date.isBefore(end) || e.date.isAtSameMomentAs(end));
            break;
          case TimeFilterOption.month:
            matchesTime = e.date.year == now.year && e.date.month == now.month;
            break;
          case TimeFilterOption.year:
            matchesTime = e.date.year == now.year;
            break;
          case TimeFilterOption.custom:
            if (customRange != null) {
              final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
              final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
              matchesTime = (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) &&
                            (e.date.isBefore(end) || e.date.isAtSameMomentAs(end));
            }
            break;
          case TimeFilterOption.all:
            matchesTime = true;
            break;
        }

        if (!matchesTime) return false;

        // Lọc theo danh mục
        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          if (e.category != categoryFilter) return false;
        }

        // Lọc theo từ khóa tìm kiếm
        if (searchQuery.isNotEmpty) {
          final matchMerchant = e.merchantName.toLowerCase().contains(searchQuery);
          final matchNote = (e.note ?? '').toLowerCase().contains(searchQuery);
          final matchCategory = e.category.toLowerCase().contains(searchQuery);
          final matchCode = (e.invoiceCode ?? '').toLowerCase().contains(searchQuery);
          if (!matchMerchant && !matchNote && !matchCategory && !matchCode) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// Trạng thái ngân sách trong tháng hiện tại
final budgetStatusProvider = Provider<BudgetStatus>((ref) {
  final expensesAsync = ref.watch(expenseProvider);
  final monthlyBudget = ref.watch(monthlyBudgetProvider);
  final now = DateTime.now();

  double totalSpentThisMonth = 0.0;
  expensesAsync.whenData((expenses) {
    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        totalSpentThisMonth += e.amount;
      }
    }
  });

  final remaining = (monthlyBudget - totalSpentThisMonth).clamp(0.0, double.infinity);
  final percentage = monthlyBudget > 0 ? (totalSpentThisMonth / monthlyBudget).clamp(0.0, 1.0) : 0.0;

  return BudgetStatus(
    monthlyBudget: monthlyBudget,
    totalSpent: totalSpentThisMonth,
    remaining: remaining,
    percentage: percentage,
  );
});
