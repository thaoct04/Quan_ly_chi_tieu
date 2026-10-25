import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Định dạng số tiền VNĐ đầy đủ: ví dụ 12.706.000 ₫
  static String formatVND(double amount) {
    return _vndFormat.format(amount).replaceAll('VND', '₫').trim();
  }

  /// Định dạng số tiền không kèm ký hiệu: ví dụ 12.706.000
  static String formatNumber(double amount) {
    return _numberFormat.format(amount.round());
  }

  /// Định dạng ngắn gọn cho trục biểu đồ: ví dụ 12.7M, 500k, 0
  static String formatCompactVND(double amount) {
    if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} Tỷ';
    } else if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} Tr';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)}k';
    } else if (amount <= 0) {
      return '0';
    }
    return amount.toStringAsFixed(0);
  }

  /// Chuyển đổi chuỗi tiền tệ tiếng Việt sang double
  static double parseVNDString(String raw) {
    if (raw.isEmpty) return 0.0;
    
    // Loại bỏ các ký tự không phải số và dấu phân cách
    String cleaned = raw.trim()
        .replaceAll('₫', '')
        .replaceAll('đ', '')
        .replaceAll('Đ', '')
        .replaceAll('VND', '')
        .replaceAll('VNĐ', '')
        .replaceAll('vnd', '')
        .replaceAll('vnđ', '')
        .replaceAll(' ', '');

    // Nếu có cả dấu chấm và dấu phẩy
    if (cleaned.contains('.') && cleaned.contains(',')) {
      int lastDot = cleaned.lastIndexOf('.');
      int lastComma = cleaned.lastIndexOf(',');
      if (lastComma > lastDot) {
        // Kiểu 12.706.000,50 -> bỏ chấm, phẩy thành chấm
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Kiểu 12,706,000.50 -> bỏ phẩy
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      // Kiểm tra xem dấu chấm là phân cách hàng nghìn hay thập phân
      // Tiền Việt Nam thường là 12.706.000 hoặc 50.000 (sau dấu chấm có 3 chữ số)
      List<String> parts = cleaned.split('.');
      bool isThousands = true;
      for (int i = 1; i < parts.length; i++) {
        if (parts[i].length != 3 && i != parts.length - 1) {
          isThousands = false;
          break;
        }
      }
      if (isThousands || parts.length > 2) {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      List<String> parts = cleaned.split(',');
      bool isThousands = true;
      for (int i = 1; i < parts.length; i++) {
        if (parts[i].length != 3 && i != parts.length - 1) {
          isThousands = false;
          break;
        }
      }
      if (isThousands || parts.length > 2) {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }
}
