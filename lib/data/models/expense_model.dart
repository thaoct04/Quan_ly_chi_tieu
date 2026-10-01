import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String merchantName;
  late double amount;
  late DateTime date;
  late String category;
  
  String? paymentMethod; // "Tiền mặt", "Chuyển khoản", "Thẻ tín dụng", "Ví điện tử"
  String? note;          // Nội dung thu/chi hoặc ghi chú
  String? invoiceCode;   // Ký hiệu / Số hóa đơn / Mã tra cứu
  String? rawOcrText;    // Văn bản OCR gốc

  @Index()
  short get yearMonth => date.year * 100 + date.month;
}
