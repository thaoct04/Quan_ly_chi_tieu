import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class CategoryConstants {
  static const List<AppCategory> categories = [
    AppCategory(
      name: 'Học phí & Giáo dục',
      icon: Icons.school_rounded,
      color: Color(0xFF3F51B5), // Indigo
    ),
    AppCategory(
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF9800), // Orange
    ),
    AppCategory(
      name: 'Mua sắm',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFE91E63), // Pink
    ),
    AppCategory(
      name: 'Di chuyển',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF2196F3), // Blue
    ),
    AppCategory(
      name: 'Hóa đơn & Dịch vụ',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF009688), // Teal
    ),
    AppCategory(
      name: 'Giải trí',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFFF5722), // Deep Orange
    ),
    AppCategory(
      name: 'Sức khỏe & Y tế',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFF44336), // Red
    ),
    AppCategory(
      name: 'Khác',
      icon: Icons.category_rounded,
      color: Color(0xFF607D8B), // Blue Grey
    ),
  ];

  static AppCategory getCategory(String? name) {
    if (name == null) return categories.last;
    return categories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase() ||
             c.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () => categories.last,
    );
  }

  static const List<String> paymentMethods = [
    'Chuyển khoản',
    'Tiền mặt',
    'Thẻ tín dụng / Ghi nợ',
    'Ví điện tử',
  ];

  static IconData getPaymentIcon(String? method) {
    switch (method) {
      case 'Tiền mặt':
        return Icons.payments_outlined;
      case 'Chuyển khoản':
        return Icons.account_balance_outlined;
      case 'Thẻ tín dụng / Ghi nợ':
        return Icons.credit_card_outlined;
      case 'Ví điện tử':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payment_outlined;
    }
  }
}
