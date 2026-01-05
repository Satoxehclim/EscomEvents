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
  final int? maxLines;
  final int? minLines;

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
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores basados en tu paleta AppColors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6); // darkSurface : lightSurface
    final primaryColor = isDark ? const Color(0xFF2979FF) : const Color(0xFF4F46E5);     // darkPrimary : lightPrimary
    final errorColor = isDark ? const Color(0xFFCF6679) : const Color(0xFFF43F5E);       // Error

    // Para campos multilinea, el icono debe estar arriba.
    final esMultilinea = maxLines != null && maxLines! > 1;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: esMultilinea ? TextInputType.multiline : keyboardType,
      onTap: onTap,
      readOnly: readOnly,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
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
            ? Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 8,
                  //top: esMultilinea ? 16 : 0,
                ),
                child: Align(
                  alignment: esMultilinea ? Alignment.topCenter : Alignment.center,
                  widthFactor: 1.0,
                  heightFactor: esMultilinea ? null : 1.0,
                  child: Icon(prefixIcon, color: Colors.grey, size: 22),
                ),
              )
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