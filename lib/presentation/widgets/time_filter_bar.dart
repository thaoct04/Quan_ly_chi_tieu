import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class TimeFilterBar extends ConsumerWidget {
  const TimeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(timeFilterProvider);
    final customRange = ref.watch(customDateRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TimeFilterOption.values.map((option) {
              final isSelected = selectedFilter == option;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      ref.read(timeFilterProvider.notifier).state = option;

                      if (option == TimeFilterOption.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: customRange ??
                              DateTimeRange(
                                start: DateTime.now().subtract(const Duration(days: 7)),
                                end: DateTime.now(),
                              ),
                          helpText: 'Chọn khoảng thời gian',
                          cancelText: 'Hủy',
                          confirmText: 'Áp dụng',
                        );
                        if (picked != null) {
                          ref.read(customDateRangeProvider.notifier).state = picked;
                        }
                      }
                    }
                  },
                  selectedColor: const Color(0xFF0F766E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade200,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        if (selectedFilter == TimeFilterOption.custom && customRange != null) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: customRange,
              );
              if (picked != null) {
                ref.read(customDateRangeProvider.notifier).state = picked;
              }
            },
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF0F766E)),
                const SizedBox(width: 4),
                Text(
                  'Từ ${DateFormat('dd/MM/yyyy').format(customRange.start)} đến ${DateFormat('dd/MM/yyyy').format(customRange.end)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
