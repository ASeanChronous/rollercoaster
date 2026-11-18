import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.categoryLabels.keys.toList();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final label = AppConstants.categoryLabels[cat] ?? cat;
          final icon = AppConstants.categoryIcons[cat] ?? Icons.category;
          final isSelected = cat == selectedCategory;

          return ChoiceChip(
            avatar: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
            label: Text(label),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[300],
            ),
            selected: isSelected,
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF334155),
              ),
            ),
            onSelected: (_) => onSelected(cat),
          );
        },
      ),
    );
  }
}
