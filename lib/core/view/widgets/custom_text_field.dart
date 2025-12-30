import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores basados en tu paleta AppColors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6); // darkSurface : lightSurface
    final primaryColor = isDark ? const Color(0xFF2979FF) : const Color(0xFF4F46E5);     // darkPrimary : lightPrimary
    final errorColor = isDark ? const Color(0xFFCF6679) : const Color(0xFFF43F5E);       // Error

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      onTap: onTap,
      readOnly: readOnly,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium, // Estilo del texto que escribe el usuario
      cursorColor: primaryColor, // El cursor toma el color primario
      decoration: InputDecoration(
        // 1. Estilo Base (Igual a la SearchBar)
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.withOpacity(0.7),
          fontSize: 14,
        ),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        
        // 2. Iconos integrados
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Colors.grey, size: 22) 
            : null,
        suffixIcon: suffixIcon,

        // 3. Bordes (La magia del diseño limpio)
        // Estado normal: Sin borde visible, solo relleno y curvas
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, 
        ),
        
        // Estado enfocado: Borde sutil del color primario
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        
        // Estado de error: Borde rojo
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
      ),
    );
  }
}