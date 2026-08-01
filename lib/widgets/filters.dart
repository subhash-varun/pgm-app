import 'package:flutter/material.dart';

import '../core/theme.dart';

class FilterBar extends StatelessWidget {
  final Widget child;
  const FilterBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 14, color: p.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class FilterChips<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return ChoiceChip(
          label: Text(label(opt)),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          showCheckmark: false,
          selectedColor: p.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : p.textPrimary,
          ),
          backgroundColor: p.surfaceAlt,
          side: BorderSide(
            color: isSelected ? p.primary : p.border,
            width: isSelected ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        );
      }).toList(),
    );
  }
}
