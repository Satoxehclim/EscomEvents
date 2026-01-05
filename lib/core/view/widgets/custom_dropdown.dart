import 'package:flutter/material.dart';

// Modelo para los elementos del dropdown.
class DropdownItem<T> {
  // Valor del elemento.
  final T valor;

  // Texto que se muestra en el dropdown.
  final String etiqueta;

  // Icono opcional para el elemento.
  final IconData? icono;

  const DropdownItem({
    required this.valor,
    required this.etiqueta,
    this.icono,
  });
}

// Dropdown personalizado
// Soporta validaciones, etiquetas, iconos y estilos consistentes
// con los demás widgets de formulario.
class CustomDropdown<T> extends StatelessWidget {
  // Etiqueta que se muestra encima del dropdown.
  final String? etiqueta;

  // Texto que se muestra cuando no hay selección.
  final String textoHint;

  // Valor actualmente seleccionado.
  final T? valorSeleccionado;

  // Lista de elementos disponibles para seleccionar.
  final List<DropdownItem<T>> elementos;

  // Callback cuando se selecciona un elemento.
  final ValueChanged<T?>? onChanged;

  // Función de validación.
  final String? Function(T?)? validador;

  // Icono que se muestra a la izquierda.
  final IconData? iconoPrefijo;

  // Si el dropdown está deshabilitado.
  final bool deshabilitado;

  // Si el dropdown debe expandirse al ancho disponible.
  final bool expandido;

  const CustomDropdown({
    super.key,
    this.etiqueta,
    required this.textoHint,
    this.valorSeleccionado,
    required this.elementos,
    this.onChanged,
    this.validador,
    this.iconoPrefijo,
    this.deshabilitado = false,
    this.expandido = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores basados en la paleta AppColors.
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final primaryColor =
        isDark ? const Color(0xFF2979FF) : const Color(0xFF4F46E5);
    final errorColor =
        isDark ? const Color(0xFFCF6679) : const Color(0xFFF43F5E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta opcional.
        if (etiqueta != null) ...[
          Text(
            etiqueta!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Dropdown.
        DropdownButtonFormField<T>(
          value: valorSeleccionado,
          hint: Text(
            textoHint,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          isExpanded: expandido,
          validator: validador,
          onChanged: deshabilitado ? null : onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: deshabilitado ? Colors.grey.shade400 : Colors.grey,
          ),
          dropdownColor: isDark
              ? const Color(0xFF2D2D2D)
              : Colors.white,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            filled: true,
            fillColor: deshabilitado
                ? backgroundColor.withOpacity(0.5)
                : backgroundColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            prefixIcon: iconoPrefijo != null
                ? Icon(
                    iconoPrefijo,
                    color: deshabilitado ? Colors.grey.shade400 : Colors.grey,
                    size: 22,
                  )
                : null,

            // Borde normal.
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),

            // Borde enfocado.
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),

            // Borde de error.
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1.5),
            ),

            // Borde deshabilitado.
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: elementos.map((elemento) {
            return DropdownMenuItem<T>(
              value: elemento.valor,
              child: Row(
                children: [
                  if (elemento.icono != null) ...[
                    Icon(
                      elemento.icono,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(elemento.etiqueta),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
