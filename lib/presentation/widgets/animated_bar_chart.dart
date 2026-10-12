import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';

class BarChartData {
  final String label;
  final double value;
  final String? subtitle;

  BarChartData(this.label, this.value, {this.subtitle});
}

class AnimatedBarChart extends StatefulWidget {
  final List<BarChartData> data;
  final String? title;
  final Color primaryColor;
  final Color secondaryColor;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.title,
    this.primaryColor = const Color(0xFF009688),
    this.secondaryColor = const Color(0xFF80CBC4),
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
      touchedIndex = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;
    
    // Vùng vẽ biểu đồ bên trong margin trục
    const double leftMargin = 55.0;
    const double rightMargin = 16.0;

    final double chartWidth = size.width - leftMargin - rightMargin;
    if (localPosition.dx < leftMargin || localPosition.dx > size.width - rightMargin) {
      setState(() => touchedIndex = null);
      return;
    }

    final double stepWidth = chartWidth / widget.data.length;
    final int index = ((localPosition.dx - leftMargin) / stepWidth).floor().clamp(0, widget.data.length - 1);

    setState(() {
      touchedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              "Không có dữ liệu trong khoảng thời gian này",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final totalValue = widget.data.fold(0.0, (sum, item) => sum + item.value);
    final maxValue = widget.data.map((e) => e.value).reduce(max);
    final avgValue = totalValue / widget.data.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với chỉ số tổng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? "Biến động chi tiêu",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tổng: ${CurrencyUtils.formatVND(totalValue)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 16, color: widget.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      "TB: ${CurrencyUtils.formatCompactVND(avgValue)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vùng vẽ biểu đồ tương tác
          GestureDetector(
            onTapDown: (details) => _handleTouch(details.localPosition, const Size(double.infinity, 200)),
            onPanUpdate: (details) => _handleTouch(details.localPosition, const Size(double.infinity, 200)),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: BarChartPainter(
                    data: widget.data,
                    progress: _animation.value,
                    touchedIndex: touchedIndex,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    maxValue: maxValue,
                  ),
                );
              },
            ),
          ),
          
          if (touchedIndex != null && touchedIndex! < widget.data.length)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.data[touchedIndex!].label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      CurrencyUtils.formatVND(widget.data[touchedIndex!].value),
                      style: TextStyle(color: widget.secondaryColor, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<BarChartData> data;
  final double progress;
  final int? touchedIndex;
  final Color primaryColor;
  final Color secondaryColor;
  final double maxValue;

  BarChartPainter({
    required this.data,
    required this.progress,
    this.touchedIndex,
    required this.primaryColor,
    required this.secondaryColor,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 52.0;
    const double rightMargin = 12.0;
    const double topMargin = 22.0;
    const double bottomMargin = 28.0;

    final double chartWidth = size.width - leftMargin - rightMargin;
    final double chartHeight = size.height - topMargin - bottomMargin;

    final double effectiveMax = maxValue == 0 ? 1000000 : (maxValue * 1.15);

    // 1. Vẽ lưới tọa độ Y và nhãn số tiền (Y-Axis grid & labels)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const int yDivisions = 4;
    for (int i = 0; i <= yDivisions; i++) {
      final double yRatio = i / yDivisions;
      final double yPos = topMargin + chartHeight * (1 - yRatio);
      final double gridValue = effectiveMax * yRatio;

      // Đường lưới nét đứt nhẹ
      canvas.drawLine(
        Offset(leftMargin, yPos),
        Offset(size.width - rightMargin, yPos),
        gridPaint,
      );

      // Nhãn trục Y
      textPainter.text = TextSpan(
        text: CurrencyUtils.formatCompactVND(gridValue),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6, yPos - textPainter.height / 2),
      );
    }

    // 2. Vẽ các cột và nhãn trục X
    final double stepWidth = chartWidth / data.length;
    final double barWidth = (stepWidth * 0.55).clamp(8.0, 36.0);

    final linePath = Path();
    bool isFirstPoint = true;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double barHeight = (item.value / effectiveMax) * chartHeight * progress;
      final double centerX = leftMargin + i * stepWidth + stepWidth / 2;
      final double leftX = centerX - barWidth / 2;
      final double topY = topMargin + chartHeight - barHeight;
      final double bottomY = topMargin + chartHeight;

      final isSelected = touchedIndex == i;

      // Lưu tọa độ cho đường nối xu hướng
      final pointY = topMargin + chartHeight - (item.value / effectiveMax) * chartHeight * progress;
      if (isFirstPoint) {
        linePath.moveTo(centerX, pointY);
        isFirstPoint = false;
      } else {
        linePath.lineTo(centerX, pointY);
      }

      // Vẽ thanh cột (Gradient bar)
      final rect = Rect.fromLTRB(leftX, topY, leftX + barWidth, bottomY);
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSelected
              ? [primaryColor, secondaryColor]
              : [
                  primaryColor.withValues(alpha: 0.85),
                  secondaryColor.withValues(alpha: 0.35),
                ],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      // Hiệu ứng đổ bóng nếu được chọn
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rrect, shadowPaint);
      }

      canvas.drawRRect(rrect, barPaint);

      // Nhãn trục X (Thời gian / Ngày)
      textPainter.text = TextSpan(
        text: item.label,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.grey.shade600,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, bottomY + 6),
      );

      // Tooltip trên đỉnh cột nếu được chạm vào
      if (isSelected && progress > 0.5) {
        final tooltipText = CurrencyUtils.formatCompactVND(item.value);
        textPainter.text = TextSpan(
          text: tooltipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        final tooltipWidth = textPainter.width + 12;
        final tooltipHeight = textPainter.height + 6;
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, topY - 14),
            width: tooltipWidth,
            height: tooltipHeight,
          ),
          const Radius.circular(6),
        );

        final tipPaint = Paint()..color = const Color(0xFF1E293B);
        canvas.drawRRect(tooltipRect, tipPaint);
        textPainter.paint(
          canvas,
          Offset(centerX - textPainter.width / 2, topY - 14 - textPainter.height / 2),
        );
      }
    }

    // 3. Vẽ đường chỉ báo xu hướng nhẹ (Trend line)
    if (data.length > 1) {
      final trendPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, trendPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.touchedIndex != touchedIndex ||
           oldDelegate.data != data;
  }
}
