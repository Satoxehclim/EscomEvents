import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class EventSearchHeader extends StatelessWidget {
  final VoidCallback onFilterTap;

  const EventSearchHeader({Key? key, required this.onFilterTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              hintText: "Buscar eventos...",
              prefixIcon: Icons.search,

            ),
          ),
          const SizedBox(width: 12),
          // Botón de filtro
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: onFilterTap,
            ),
          ),
        ],
      ),
    );
  }
}