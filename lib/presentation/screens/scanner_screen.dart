import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/receipt_parser.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _imagePath;
  ReceiptData? _receiptData;

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  final _invoiceCodeController = TextEditingController();

  String _selectedCategory = 'Học phí & Giáo dục';
  String _selectedPaymentMethod = 'Chuyển khoản';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _invoiceCodeController.dispose();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _imagePath = image.path;
        _isProcessing = true;
      });

      final result = await ReceiptParser.parseImage(image.path);
      _populateData(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể quét ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _populateData(ReceiptData result) {
    setState(() {
      _receiptData = result;
      _merchantController.text = result.merchantName;
      _amountController.text = CurrencyUtils.formatNumber(result.totalAmount);
      _selectedDate = result.date ?? DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _selectedCategory = result.category;
      _selectedPaymentMethod = result.paymentMethod;
      _noteController.text = result.note ?? '';
      _invoiceCodeController.text = result.invoiceCode ?? '';
    });
  }

  /// Nạp mẫu hóa đơn VKU mô phỏng trực tiếp từ ảnh người dùng cung cấp
  void _loadSampleVkuReceipt() {
    final vkuText = """
TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN VÀ TRUYỀN THÔNG VIỆT - HÀN
VKU
Địa chỉ: Đô thị Đại học, đường Nam Kỳ Khởi Nghĩa, Phường Ngũ Hành Sơn, TP Đà Nẵng, Việt Nam.
Mã số thuế: 0402037673 Số điện thoại: 0236.3667114
Số tài khoản: 56010001499995 tại Ngân hàng BIDV - Chi nhánh Hải Vân
HÓA ĐƠN BÁN HÀNG
Ký hiệu: 2C26THP
Số: 00008696
Ngày 14 tháng 9 năm 2026
Mã CQT: 008BB6FDE5156046F4AF6347E5CFB6073B
Họ và tên người nộp: Nguyễn Văn Hoàng Phú
Mã sinh viên: 23IT.B164 Lớp: 23SE5
Căn cước công dân: 049205000744
Số tiền thu: 12.706.000
Hình thức thu: TM [ ] CK [X]
Viết bằng chữ: Mười hai triệu bảy trăm linh sáu nghìn đồng chẵn.
Nội dung thu: Học phí học kỳ 1 năm học 2026-2027
Ký bởi: TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN VÀ TRUYỀN THÔNG VIỆT - HÀN
Ký ngày: 14/09/2026
Mã tra cứu hóa đơn: XAFXTE8VA5KP
""";
    final result = ReceiptParser.extractDataFromLines(vkuText.split('\n'), vkuText);
    _populateData(result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nhận diện thành công hóa đơn mẫu VKU!')),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Chọn ngày hóa đơn',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveExpense() {
    final merchant = _merchantController.text.trim();
    final amount = CurrencyUtils.parseVNDString(_amountController.text);

    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đơn vị/cửa hàng')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final expense = Expense()
      ..merchantName = merchant
      ..amount = amount
      ..date = _selectedDate
      ..category = _selectedCategory
      ..paymentMethod = _selectedPaymentMethod
      ..note = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null
      ..invoiceCode = _invoiceCodeController.text.trim().isNotEmpty ? _invoiceCodeController.text.trim() : null
      ..rawOcrText = _receiptData?.rawText;

    ref.read(expenseProvider.notifier).addExpense(expense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu thành công: $merchant (${CurrencyUtils.formatVND(amount)})')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quét & Trích xuất Hóa đơn OCR',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Nút chọn nguồn ảnh
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _processImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text("Chụp ảnh hóa đơn"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _processImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F766E)),
                  label: const Text("Tải từ thư viện", style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F766E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nút thử nghiệm nhanh với hóa đơn mẫu VKU
          Center(
            child: TextButton.icon(
              onPressed: _loadSampleVkuReceipt,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text("Thử nghiệm nhận diện hóa đơn ĐH Việt - Hàn (VKU)"),
            ),
          ),
          const SizedBox(height: 14),

          // Trạng thái đang nhận diện OCR
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F766E)),
                  SizedBox(height: 14),
                  Text(
                    "Đang phân tích hình ảnh và bóc tách dữ liệu OCR...",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                  ),
                ],
              ),
            ),

          // Ảnh hóa đơn đã chụp/chọn
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2. Form kết quả nhận diện & chỉnh sửa
          if (_merchantController.text.isNotEmpty || _amountController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Thông tin bóc tách từ Hóa đơn",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "OCR OK",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tên đơn vị
                  _buildTextField(
                    controller: _merchantController,
                    label: "Tên Đơn vị / Cửa hàng / Trường học",
                    icon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 14),

                  // Số tiền VNĐ
                  _buildTextField(
                    controller: _amountController,
                    label: "Số tiền thanh toán (VNĐ)",
                    icon: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                    suffixText: "₫",
                  ),
                  const SizedBox(height: 14),

                  // Ngày hóa đơn
                  InkWell(
                    onTap: _selectDate,
                    child: IgnorePointer(
                      child: _buildTextField(
                        controller: _dateController,
                        label: "Ngày hóa đơn (dd/MM/yyyy)",
                        icon: Icons.calendar_today_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Danh mục
                  const Text(
                    "Danh mục chi tiêu",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: CategoryConstants.categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.name,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 18),
                                const SizedBox(width: 10),
                                Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phương thức thanh toán
                  const Text(
                    "Phương thức thanh toán",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CategoryConstants.paymentMethods.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      return ChoiceChip(
                        avatar: Icon(CategoryConstants.getPaymentIcon(method), size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
                        label: Text(method),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPaymentMethod = method);
                        },
                        selectedColor: const Color(0xFF0F766E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Nội dung thu / Ghi chú
                  _buildTextField(
                    controller: _noteController,
                    label: "Nội dung thu/chi (Ví dụ: Học phí HK1...)",
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 14),

                  // Ký hiệu & Số hóa đơn
                  _buildTextField(
                    controller: _invoiceCodeController,
                    label: "Ký hiệu / Số hóa đơn / Mã tra cứu",
                    icon: Icons.receipt_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu giao dịch
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveExpense,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text("Lưu vào Sổ Chi Tiêu", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0F766E), size: 20),
            suffixText: suffixText,
            suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F766E)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
