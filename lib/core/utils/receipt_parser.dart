import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'currency_utils.dart';

class ReceiptData {
  final double totalAmount;
  final DateTime? date;
  final String merchantName;
  final String category;
  final String paymentMethod;
  final String? note;
  final String? invoiceCode;
  final String rawText;

  ReceiptData({
    required this.totalAmount,
    this.date,
    required this.merchantName,
    required this.category,
    required this.paymentMethod,
    this.note,
    this.invoiceCode,
    required this.rawText,
  });
}

class ReceiptParser {
  static Future<ReceiptData> parseImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    return extractDataFromRecognizedText(recognizedText);
  }

  static ReceiptData extractDataFromRecognizedText(RecognizedText recognizedText) {
    List<String> lines = recognizedText.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    String rawText = lines.join('\n');
    return extractDataFromLines(lines, rawText);
  }

  static ReceiptData extractDataFromLines(List<String> lines, [String? fullText]) {
    final rawText = fullText ?? lines.join('\n');

    // 1. Trích xuất Tên đơn vị / Cửa hàng
    String merchantName = _extractMerchantName(lines, rawText);

    // 2. Trích xuất Ngày tháng
    DateTime? date = _extractDate(lines, rawText);

    // 3. Trích xuất Số tiền VNĐ
    double amount = _extractAmount(lines, rawText);

    // 4. Trích xuất Nội dung / Ghi chú
    String? note = _extractNote(lines, rawText);

    // 5. Trích xuất Ký hiệu & Số hóa đơn
    String? invoiceCode = _extractInvoiceCode(lines, rawText);

    // 6. Trích xuất Hình thức thanh toán
    String paymentMethod = _extractPaymentMethod(lines, rawText);

    // 7. Xác định Danh mục (Category)
    String category = _detectCategory(merchantName, note, rawText);

    return ReceiptData(
      totalAmount: amount,
      date: date ?? DateTime.now(),
      merchantName: merchantName,
      category: category,
      paymentMethod: paymentMethod,
      note: note,
      invoiceCode: invoiceCode,
      rawText: rawText,
    );
  }

  /// Trích xuất tên đơn vị phát hành / cửa hàng
  static String _extractMerchantName(List<String> lines, String rawText) {
    // Ưu tiên 1: Ký bởi: ...
    final signByRegex = RegExp(r'Ký\s*bởi\s*[:\s]*([^\n]+)', caseSensitive: false);
    final signMatch = signByRegex.firstMatch(rawText);
    if (signMatch != null && signMatch.group(1)!.trim().length > 3) {
      return _cleanMerchantName(signMatch.group(1)!);
    }

    // Ưu tiên 2: Đơn vị bán hàng / Bên bán: ...
    final sellerRegex = RegExp(r'(?:Đơn vị bán|Bên bán|Đơn vị phát hành|Nhà cung cấp)\s*[:\s]*([^\n]+)', caseSensitive: false);
    final sellerMatch = sellerRegex.firstMatch(rawText);
    if (sellerMatch != null && sellerMatch.group(1)!.trim().length > 3) {
      return _cleanMerchantName(sellerMatch.group(1)!);
    }

    // Ưu tiên 3: Biên lai CHUYỂN TIỀN NGÂN HÀNG (MB, VCB, Techcombank, VietinBank...)
    // Cấu trúc: [Logo] → "Chuyển tiền thành công" → Số tiền → Thời gian → [Tên người nhận] → Ngân hàng nhận
    if (_isBankTransferReceipt(rawText)) {
      final recipient = _extractBankTransferRecipient(lines, rawText);
      if (recipient != null) return recipient;
    }

    // Ưu tiên 4: Tìm dòng đầu tiên chứa các tiền tố tổ chức/doanh nghiệp
    final orgKeywords = [
      'trường đại học', 'trường đh', 'trường cao đẳng', 'trường',
      'công ty', 'cty tnhh', 'cty cp', 'doanh nghiệp', 'tập đoàn',
      'siêu thị', 'co.opmart', 'winmart', 'lotte mart', 'big c', 'go!', 'aeon',
      'circle k', 'gs25', '7-eleven', 'family mart', 'ministop',
      'highlands coffee', 'the coffee house', 'phúc long', 'starbucks', 'kfc', 'lotteria', 'jollibee',
      'bệnh viện', 'phòng khám', 'nhà thuốc', 'pharmacity', 'long châu',
      'trung tâm', 'nhà hàng', 'quán cà phê', 'quán cafe', 'quán ăn', 'cửa hàng',
    ];

    for (String line in lines.take(8)) {
      final lower = line.toLowerCase();
      for (String kw in orgKeywords) {
        if (lower.contains(kw)) {
          return _cleanMerchantName(line);
        }
      }
    }

    // Ưu tiên 5: Dòng đầu tiên hợp lệ không phải tiêu đề chung hay địa chỉ/MST
    for (String line in lines.take(5)) {
      final lower = line.toLowerCase();
      if (_isIgnoredHeaderLine(lower)) continue;
      if (line.trim().length >= 4) {
        return _cleanMerchantName(line);
      }
    }

    return "Đơn vị chưa xác định";
  }

  /// Kiểm tra xem đây có phải biên lai chuyển tiền ngân hàng không
  static bool _isBankTransferReceipt(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains('chuyển tiền thành công') ||
           lower.contains('chuyen tien thanh cong') ||
           lower.contains('giao dịch thành công') ||
           lower.contains('thanh toán thành công') ||
           lower.contains('transfer successful') ||
           lower.contains('payment successful');
  }

  /// Trích xuất tên người nhận trong biên lai chuyển tiền ngân hàng
  static String? _extractBankTransferRecipient(List<String> lines, String rawText) {
    final bankNames = [
      'vietcombank', 'vcb', 'techcombank', 'tcb', 'mbbank', 'mb bank',
      'vietinbank', 'ctg', 'bidv', 'agribank', 'tpbank', 'vpbank',
      'acb', 'hdbank', 'sacombank', 'shb', 'ocb', 'seabank', 'msb',
      'abbank', 'pvcombank', 'baovietbank', 'pgbank', 'vib', 'eximbank',
      'namabank', 'dongabank', 'ncb', 'gpbank', 'cbbank',
      'momo', 'zalopay', 'vnpay', 'viettel money', 'shopee pay',
    ];
    final ignoredPhrases = [
      'chuyển tiền thành công', 'giao dịch thành công',
      'thanh toán thành công', 'transfer successful',
      'payment successful', 'giao dịch được xác nhận',
      'vui lòng không chỉnh sửa', 'hình ảnh này',
      'chuyen tien', 'chuyển tiền', 'nội dung', 'noi dung',
    ];

    bool foundAmountOrTime = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (_looksLikeAmountLine(line) || _looksLikeTimeLine(line)) {
        foundAmountOrTime = true;
        continue;
      }
      if (!foundAmountOrTime) continue;

      bool isIgnored = false;
      for (final phrase in ignoredPhrases) {
        if (lower.contains(phrase)) { isIgnored = true; break; }
      }
      if (isIgnored) continue;

      // Bỏ qua tên ngân hàng đơn thuần
      bool isBankName = bankNames.any((b) => lower.trim() == b);
      if (isBankName) continue;

      // Bỏ qua số tài khoản thuần
      if (RegExp(r'^\d[\d\s]{5,}$').hasMatch(line)) continue;

      // Bỏ qua dòng thời gian
      if (RegExp(r'\d{1,2}:\d{2}').hasMatch(line)) continue;

      // Bỏ qua dòng ngắn
      if (line.length < 4) continue;

      // Bỏ qua dòng chứa tên ngân hàng ("Vietinbank (CTG)")
      bool containsBank = bankNames.any((b) => lower.contains(b));
      if (containsBank) continue;

      // Dòng đầu tiên hợp lệ → tên người nhận
      return _cleanMerchantName(line);
    }
    return null;
  }

  /// Kiểm tra xem dòng có phải số tiền không
  static bool _looksLikeAmountLine(String line) {
    return RegExp(r'[\d,\.]{3,}\s*(?:VND|VNĐ|đ|₫)', caseSensitive: false).hasMatch(line) ||
           RegExp(r'^[\d]{1,3}(?:[,\.]\d{3})+$').hasMatch(line.trim());
  }

  /// Kiểm tra xem dòng có phải thời gian không
  static bool _looksLikeTimeLine(String line) {
    return RegExp(r'\d{1,2}:\d{2}.*\d{2}/\d{2}/\d{4}').hasMatch(line) ||
           RegExp(r'\d{2}/\d{2}/\d{4}.*\d{1,2}:\d{2}').hasMatch(line);
  }

  static bool _isIgnoredHeaderLine(String lower) {
    return lower.contains('cộng hòa xã hội') ||
           lower.contains('độc lập - tự do') ||
           lower.contains('hóa đơn bán hàng') ||
           lower.contains('hóa đơn giá trị') ||
           lower.contains('hóa đơn điện tử') ||
           lower.contains('phiếu thu') ||
           lower.contains('phiếu thanh toán') ||
           lower.contains('phiếu tính tiền') ||
           lower.contains('mã số thuế') ||
           lower.contains('địa chỉ:') ||
           lower.contains('số điện thoại:') ||
           lower.contains('số tài khoản:') ||
           lower.contains('chuyển tiền thành công') ||
           lower.contains('giao dịch thành công') ||
           lower.contains('thanh toán thành công') ||
           lower.contains('giao dịch được xác nhận') ||
           lower.contains('vui lòng không chỉnh sửa');
  }

  static String _cleanMerchantName(String name) {
    String cleaned = name
        .replaceAll(RegExp(r'^(Ký bởi|Đơn vị bán|Bên bán|Cửa hàng|Tên đơn vị)\s*[:\-]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Tách tên thực trước mã số tài khoản dạng NAME_ACCOUNTNUMBER
    final underscoreIdx = cleaned.lastIndexOf('_');
    if (underscoreIdx > 3) {
      final afterUnderscore = cleaned.substring(underscoreIdx + 1);
      if (RegExp(r'^\d{6,}$').hasMatch(afterUnderscore)) {
        cleaned = cleaned.substring(0, underscoreIdx).trim();
      }
    }

    return cleaned;
  }

  /// Trích xuất Ngày tháng từ hóa đơn (Đặc biệt hỗ trợ chuẩn tiếng Việt "Ngày 14 tháng 9 năm 2026")
  static DateTime? _extractDate(List<String> lines, String rawText) {
    // Mẫu 1: "Ngày 14 tháng 9 năm 2026" hoặc "Ngày 14 tháng 09 năm 2026"
    final vnDateRegex = RegExp(
      r'Ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{4})',
      caseSensitive: false,
    );
    final vnMatch = vnDateRegex.firstMatch(rawText);
    if (vnMatch != null) {
      final d = _createValidDate(
        int.parse(vnMatch.group(1)!),
        int.parse(vnMatch.group(2)!),
        int.parse(vnMatch.group(3)!),
      );
      if (d != null) return d;
    }

    // Mẫu 2: "Ký ngày: 14/09/2026" hoặc "Ngày: 14/09/2026 10:30"
    final labeledDateRegex = RegExp(
      r'(?:Ký\s*ngày|Ngày\s*lập|Ngày\s*hóa\s*đơn|Ngày|Date|Time)\s*[:\s]*(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
      caseSensitive: false,
    );
    final labeledMatch = labeledDateRegex.firstMatch(rawText);
    if (labeledMatch != null) {
      final d = _createValidDate(
        int.parse(labeledMatch.group(1)!),
        int.parse(labeledMatch.group(2)!),
        int.parse(labeledMatch.group(3)!),
      );
      if (d != null) return d;
    }

    // Mẫu 3: dd/MM/yyyy hoặc dd-MM-yyyy
    final slashDateRegex = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b');
    for (String line in lines) {
      final match = slashDateRegex.firstMatch(line);
      if (match != null) {
        final d = _createValidDate(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
        if (d != null) return d;
      }
    }

    // Mẫu 4: yyyy/MM/dd hoặc yyyy-MM-dd
    final isoDateRegex = RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b');
    for (String line in lines) {
      final match = isoDateRegex.firstMatch(line);
      if (match != null) {
        final d = _createValidDate(
          int.parse(match.group(3)!),
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
        );
        if (d != null) return d;
      }
    }

    return null;
  }

  static DateTime? _createValidDate(int day, int month, int year) {
    if (year < 100) year += 2000;
    if (year < 2000 || year > 2099) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Trích xuất Số tiền VNĐ chính xác
  static double _extractAmount(List<String> lines, String rawText) {
    // Ưu tiên 1: Các dòng có nhãn số tiền chính xác
    final labelRegex = RegExp(
      r'(?:Số\s*tiền\s*thu|Số\s*tiền\s*thanh\s*toán|Tổng\s*tiền\s*thanh\s*toán|Tổng\s*thanh\s*toán|Tổng\s*cộng|Tổng\s*tiền|Thành\s*tiền|Cộng\s*tiền\s*hàng|Grand\s*Total|Total\s*Amount|Payment\s*Amount|Số\s*tiền)\s*[:\s]*([0-9.,]+)',
      caseSensitive: false,
    );

    final labelMatch = labelRegex.firstMatch(rawText);
    if (labelMatch != null) {
      final numStr = labelMatch.group(1)!;
      final parsed = CurrencyUtils.parseVNDString(numStr);
      if (parsed > 0) return parsed;
    }

    // Ưu tiên 2: Tìm kiếm trong từng dòng có từ khóa số tiền
    final amountKeywords = [
      'số tiền thu', 'tổng tiền thanh toán', 'tổng thanh toán', 'tổng cộng',
      'thành tiền', 'số tiền', 'total', 'grand total', 'payment'
    ];

    for (String line in lines) {
      final lower = line.toLowerCase();
      for (String kw in amountKeywords) {
        if (lower.contains(kw)) {
          final numberMatches = RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,9})').allMatches(line);
          for (var nm in numberMatches) {
            final val = CurrencyUtils.parseVNDString(nm.group(0)!);
            if (val > 0) return val;
          }
        }
      }
    }

    // Ưu tiên 3: Tìm tất cả số tiền có định dạng VNĐ (ví dụ 12.706.000 hoặc 50.000)
    List<double> candidates = [];
    final generalPattern = RegExp(r'([0-9]{1,3}(?:\.[0-9]{3})+|[0-9]{1,3}(?:,[0-9]{3})+|\b[0-9]{4,9}\b)');
    for (String line in lines) {
      // Bỏ qua mã số thuế, số tài khoản, số điện thoại, căn cước công dân
      final lower = line.toLowerCase();
      if (lower.contains('mã số thuế') ||
          lower.contains('mst') ||
          lower.contains('căn cước') ||
          lower.contains('cccd') ||
          lower.contains('cmnd') ||
          lower.contains('số tài khoản') ||
          lower.contains('stk') ||
          lower.contains('điện thoại') ||
          lower.contains('mã sinh viên') ||
          lower.contains('mã tra cứu')) {
        continue;
      }

      final matches = generalPattern.allMatches(line);
      for (var m in matches) {
        final val = CurrencyUtils.parseVNDString(m.group(0)!);
        if (val >= 1000 && val <= 1000000000) { // Giới hạn số tiền hợp lý
          candidates.add(val);
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.last; // Lấy số lớn nhất (thường là tổng tiền)
    }

    return 0.0;
  }

  /// Trích xuất Nội dung / Ghi chú (Ví dụ: "Học phí học kỳ 1 năm học 2026-2027")
  static String? _extractNote(List<String> lines, String rawText) {
    final noteRegex = RegExp(
      r'(?:Nội\s*dung\s*thu|Nội\s*dung|Diễn\s*giải|Lý\s*do|Ghi\s*chú|Description)\s*[:\s]*([^\n]+)',
      caseSensitive: false,
    );
    final match = noteRegex.firstMatch(rawText);
    if (match != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    return null;
  }

  /// Trích xuất Ký hiệu & Số hóa đơn
  static String? _extractInvoiceCode(List<String> lines, String rawText) {
    String? kyHieu;
    String? soHd;

    final kyHieuRegex = RegExp(r'Ký\s*hiệu\s*[:\s]*([A-Za-z0-9]+)', caseSensitive: false);
    final khMatch = kyHieuRegex.firstMatch(rawText);
    if (khMatch != null) {
      kyHieu = khMatch.group(1);
    }

    final soHdRegex = RegExp(r'Số\s*[:\s]*([0-9]{4,10})', caseSensitive: false);
    final soMatch = soHdRegex.firstMatch(rawText);
    if (soMatch != null) {
      soHd = soMatch.group(1);
    }

    if (kyHieu != null && soHd != null) {
      return '$kyHieu / $soHd';
    } else if (soHd != null) {
      return 'Số: $soHd';
    } else if (kyHieu != null) {
      return 'Ký hiệu: $kyHieu';
    }

    final lookupRegex = RegExp(r'Mã\s*tra\s*cứu(?:\s*hóa\s*đơn)?\s*[:\s]*([A-Za-z0-9]+)', caseSensitive: false);
    final lookupMatch = lookupRegex.firstMatch(rawText);
    if (lookupMatch != null) {
      return 'Mã tra cứu: ${lookupMatch.group(1)}';
    }

    return null;
  }

  /// Trích xuất Hình thức thanh toán (TM / CK / Tiền mặt / Chuyển khoản...)
  static String _extractPaymentMethod(List<String> lines, String rawText) {
    final upper = rawText.toUpperCase();

    if (upper.contains('CK [X]') ||
        upper.contains('CK[X]') ||
        upper.contains('HÌNH THỨC THU: CK') ||
        upper.contains('CHUYỂN KHOẢN') ||
        upper.contains('TRANSFER') ||
        upper.contains('VIETQR') ||
        upper.contains('BANKING')) {
      return 'Chuyển khoản';
    }

    if (upper.contains('TM [X]') ||
        upper.contains('TM[X]') ||
        upper.contains('HÌNH THỨC THU: TM') ||
        upper.contains('TIỀN MẶT') ||
        upper.contains('CASH')) {
      return 'Tiền mặt';
    }

    if (upper.contains('THẺ') ||
        upper.contains('VISA') ||
        upper.contains('MASTERCARD') ||
        upper.contains('POS') ||
        upper.contains('CREDIT') ||
        upper.contains('DEBIT')) {
      return 'Thẻ tín dụng / Ghi nợ';
    }

    if (upper.contains('MOMO') ||
        upper.contains('ZALOPAY') ||
        upper.contains('VNPAY') ||
        upper.contains('SHOPEEPAY')) {
      return 'Ví điện tử';
    }

    // Mặc định
    return 'Chuyển khoản';
  }

  /// Tự động phân loại danh mục chi tiêu
  static String _detectCategory(String merchant, String? note, String rawText) {
    final combined = '$merchant ${note ?? ''} $rawText'.toLowerCase();

    if (combined.contains('học phí') ||
        combined.contains('học kỳ') ||
        combined.contains('trường') ||
        combined.contains('đại học') ||
        combined.contains('sinh viên') ||
        combined.contains('khóa học') ||
        combined.contains('giáo dục') ||
        combined.contains('vku') ||
        combined.contains('sách')) {
      return 'Học phí & Giáo dục';
    }

    if (combined.contains('cà phê') ||
        combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('nhà hàng') ||
        combined.contains('quán') ||
        combined.contains('trà sữa') ||
        combined.contains('cơm') ||
        combined.contains('phở') ||
        combined.contains('bún') ||
        combined.contains('lẩu') ||
        combined.contains('kfc') ||
        combined.contains('lotteria') ||
        combined.contains('ăn uống') ||
        combined.contains('ẩm thực')) {
      return 'Ăn uống';
    }

    if (combined.contains('siêu thị') ||
        combined.contains('mart') ||
        combined.contains('co.op') ||
        combined.contains('winmart') ||
        combined.contains('shopee') ||
        combined.contains('tiki') ||
        combined.contains('lazada') ||
        combined.contains('quần áo') ||
        combined.contains('mua sắm') ||
        combined.contains('thời trang')) {
      return 'Mua sắm';
    }

    if (combined.contains('xăng') ||
        combined.contains('petrolimex') ||
        combined.contains('grab') ||
        combined.contains('be ') ||
        combined.contains('taxi') ||
        combined.contains('vé xe') ||
        combined.contains('vé máy bay') ||
        combined.contains('gửi xe')) {
      return 'Di chuyển';
    }

    if (combined.contains('điện lực') ||
        combined.contains('tiền điện') ||
        combined.contains('tiền nước') ||
        combined.contains('viễn thông') ||
        combined.contains('internet') ||
        combined.contains('viettel') ||
        combined.contains('fpt') ||
        combined.contains('vnpt') ||
        combined.contains('thuê nhà')) {
      return 'Hóa đơn & Dịch vụ';
    }

    if (combined.contains('bệnh viện') ||
        combined.contains('phòng khám') ||
        combined.contains('thuốc') ||
        combined.contains('nhà thuốc') ||
        combined.contains('pharmacity') ||
        combined.contains('long châu') ||
        combined.contains('y tế') ||
        combined.contains('nha khoa')) {
      return 'Sức khỏe & Y tế';
    }

    if (combined.contains('cinema') ||
        combined.contains('cgv') ||
        combined.contains('lotte') ||
        combined.contains('rạp') ||
        combined.contains('game') ||
        combined.contains('du lịch') ||
        combined.contains('giải trí')) {
      return 'Giải trí';
    }

    return 'Khác';
  }
}
