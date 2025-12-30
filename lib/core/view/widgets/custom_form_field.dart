import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String? label;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomInputField({
    Key? key,
    this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores derivados de tu AppColors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6); // darkSurface : lightSurface
    final primaryColor = isDark ? const Color(0xFF2979FF) : const Color(0xFF4F46E5);     // darkPrimary : lightPrimary
    final errorColor = isDark ? const Color(0xFFCF6679) : const Color(0xFFF43F5E);       // Error estándar : lightAccent

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta opcional fuera del input para mayor limpieza visual
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // El campo de texto
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: theme.textTheme.bodyMedium, // Texto del usuario
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
            filled: true,
            fillColor: backgroundColor,
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: Colors.grey) 
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            
            // Borde por defecto (sin linea, solo relleno)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, 
            ),
            
            // Borde cuando se selecciona (Highlight con color primario)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            
            // Borde cuando hay error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}