import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';

class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData(this.label, this.value, this.color);
}

class AnimatedPieChart extends StatefulWidget {
  final List<PieChartData> data;
  final String? title;

  const AnimatedPieChart({
    super.key,
    required this.data,
    this.title,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant AnimatedPieChart oldWidget) {
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

  void _handleTap(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;

    final double distance = sqrt(dx * dx + dy * dy);
    final double radius = min(size.width / 2, size.height / 2) - 10;
    final double innerRadius = radius * 0.58;

    // Chạm vào phần rỗng bên trong -> bỏ chọn
    if (distance < innerRadius || distance > radius + 15) {
      setState(() => touchedIndex = null);
      return;
    }

    double angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    // Biểu đồ bắt đầu vẽ từ góc -pi / 2 (đỉnh trên cùng)
    angle = (angle + pi / 2) % (2 * pi);

    final double total = widget.data.fold(0.0, (sum, e) => sum + e.value);
    if (total == 0) return;

    double currentAngle = 0;
    for (int i = 0; i < widget.data.length; i++) {
      final double sweepAngle = (widget.data[i].value / total) * 2 * pi;
      if (angle >= currentAngle && angle <= currentAngle + sweepAngle) {
        setState(() {
          touchedIndex = (touchedIndex == i) ? null : i;
        });
        return;
      }
      currentAngle += sweepAngle;
    }

    setState(() => touchedIndex = null);
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
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              "Chưa có dữ liệu phân loại",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final double total = widget.data.fold(0.0, (sum, e) => sum + e.value);

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
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Vùng Donut Chart tròn tương tác
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition, const Size(220, 220)),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(220, 220),
                      painter: DonutChartPainter(
                        data: widget.data,
                        progress: _animation.value,
                        touchedIndex: touchedIndex,
                        total: total,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Chú thích màu sắc (Legend) chi tiết
          const Text(
            "Chú thích tỷ lệ:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = widget.data[index];
              final percent = total > 0 ? (item.value / total * 100) : 0.0;
              final isSelected = touchedIndex == index;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    touchedIndex = (touchedIndex == index) ? null : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: item.color.withValues(alpha: 0.5)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyUtils.formatVND(item.value),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double progress;
  final int? touchedIndex;
  final double total;

  DonutChartPainter({
    required this.data,
    required this.progress,
    this.touchedIndex,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width / 2, size.height / 2) - 12;
    const double strokeWidth = 26.0;

    double currentAngle = -pi / 2; // Bắt đầu từ 12 giờ

    final Paint slicePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double sweepAngle = (item.value / total) * 2 * pi * progress;
      final isSelected = touchedIndex == i;

      slicePaint.color = item.color;
      slicePaint.strokeWidth = isSelected ? (strokeWidth + 8) : strokeWidth;

      // Góc bù nhẹ để tạo khe hở giữa các lát cắt
      final double gap = data.length > 1 ? 0.03 : 0.0;
      final double actualSweep = max(0.0, sweepAngle - gap);

      final Rect arcRect = Rect.fromCircle(
        center: center,
        radius: isSelected ? (radius + 2) : radius,
      );

      // Hiệu ứng phát sáng nhẹ khi chọn
      if (isSelected) {
        final glowPaint = Paint()
          ..color = item.color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 14
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(arcRect, currentAngle + gap / 2, actualSweep, false, glowPaint);
      }

      canvas.drawArc(arcRect, currentAngle + gap / 2, actualSweep, false, slicePaint);

      currentAngle += sweepAngle;
    }

    // Vẽ thông tin ở tâm biểu đồ Donut
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (touchedIndex != null && touchedIndex! < data.length) {
      final selected = data[touchedIndex!];
      final percent = (selected.value / total * 100).toStringAsFixed(1);

      textPainter.text = TextSpan(
        children: [
          TextSpan(
            text: '${selected.label}\n',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          TextSpan(
            text: '$percent%\n',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: selected.color,
            ),
          ),
          TextSpan(
            text: CurrencyUtils.formatCompactVND(selected.value),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      );
    } else {
      textPainter.text = TextSpan(
        children: [
          const TextSpan(
            text: 'Tổng chi\n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          TextSpan(
            text: CurrencyUtils.formatCompactVND(total),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      );
    }

    textPainter.layout(maxWidth: radius * 1.3);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.touchedIndex != touchedIndex ||
           oldDelegate.data != data;
  }
}
