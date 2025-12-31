import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:flutter/material.dart';

/// Tipos de botón disponibles.
enum CustomButtonType { primary, secondary, outlined, text }

/// Botón reutilizable que sigue la estética de la aplicación.
///
/// Permite personalizar el tipo, tamaño, iconos y estado de carga.
class CustomButton extends StatelessWidget {
  /// Texto del botón.
  final String texto;

  /// Callback al presionar el botón.
  final VoidCallback? onPressed;

  /// Tipo de botón (primary, secondary, outlined, text).
  final CustomButtonType tipo;

  /// Icono opcional al inicio del botón.
  final IconData? iconoInicio;

  /// Icono opcional al final del botón.
  final IconData? iconoFin;

  /// Indica si el botón ocupa todo el ancho disponible.
  final bool anchoCompleto;

  /// Indica si el botón está en estado de carga.
  final bool cargando;

  /// Padding interno del botón.
  final EdgeInsetsGeometry? padding;

  /// Radio del borde del botón.
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.texto,
    this.onPressed,
    this.tipo = CustomButtonType.primary,
    this.iconoInicio,
    this.iconoFin,
    this.anchoCompleto = true,
    this.cargando = false,
    this.padding,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores según el tema.
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    // Determina los colores según el tipo de botón.
    Color botonColor;
    Color textoColor;
    Color? bordeColor;

    switch (tipo) {
      case CustomButtonType.primary:
        botonColor = primaryColor;
        textoColor = Colors.white;
        bordeColor = null;
        break;
      case CustomButtonType.secondary:
        botonColor = secondaryColor;
        textoColor = isDark ? Colors.black : Colors.white;
        bordeColor = null;
        break;
      case CustomButtonType.outlined:
        botonColor = Colors.transparent;
        textoColor = primaryColor;
        bordeColor = primaryColor;
        break;
      case CustomButtonType.text:
        botonColor = Colors.transparent;
        textoColor = primaryColor;
        bordeColor = null;
        break;
    }

    final defaultPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    Widget contenidoBoton = cargando
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textoColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconoInicio != null) ...[
                Icon(iconoInicio, color: textoColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                texto,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (iconoFin != null) ...[
                const SizedBox(width: 8),
                Icon(iconoFin, color: textoColor, size: 20),
              ],
            ],
          );

    Widget boton = Material(
      color: botonColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: cargando ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: defaultPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: bordeColor != null
                ? Border.all(color: bordeColor, width: 1.5)
                : null,
          ),
          child: Center(child: contenidoBoton),
        ),
      ),
    );

    if (anchoCompleto) {
      return SizedBox(width: double.infinity, child: boton);
    }

    return boton;
  }
}
