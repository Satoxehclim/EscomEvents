import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:flutter/material.dart';

/// Diálogo para que el estudiante califique un evento.
class DialogoCalificarEvento extends StatefulWidget {
  final String nombreEvento;
  final Future<bool> Function(int calificacion, String? comentario) onCalificar;

  const DialogoCalificarEvento({
    super.key,
    required this.nombreEvento,
    required this.onCalificar,
  });

  /// Muestra el diálogo de calificación.
  static Future<void> mostrar({
    required BuildContext context,
    required String nombreEvento,
    required Future<bool> Function(int calificacion, String? comentario) onCalificar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogoCalificarEvento(
        nombreEvento: nombreEvento,
        onCalificar: onCalificar,
      ),
    );
  }

  @override
  State<DialogoCalificarEvento> createState() => _DialogoCalificarEventoState();
}

class _DialogoCalificarEventoState extends State<DialogoCalificarEvento> {
  int _calificacion = 0;
  final _comentarioController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return AlertDialog(
      title: const Text('Calificar evento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombreEvento,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Qué te pareció el evento?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Estrellas de calificación.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final estrella = index + 1;
                return IconButton(
                  onPressed: _enviando
                      ? null
                      : () => setState(() => _calificacion = estrella),
                  icon: Icon(
                    estrella <= _calificacion
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 40,
                    color: estrella <= _calificacion
                        ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                        : theme.colorScheme.outline,
                  ),
                );
              }),
            ),
            if (_calificacion > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _obtenerTextoCalificacion(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Comentario (opcional)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              enabled: !_enviando,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Cuéntanos tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                tipo: CustomButtonType.outlined,
                texto: 'Cancelar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                onPressed: _calificacion > 0 && !_enviando
                    ? () async {
                        setState(() => _enviando = true);
                        final comentario = _comentarioController.text.trim();
                        final exito = await widget.onCalificar(
                          _calificacion,
                          comentario.isEmpty ? null : comentario,
                        );
                        if (mounted) {
                          Navigator.of(context).pop(exito);
                        }
                      }
                    : null,
                texto: _enviando ? 'Enviando...' : 'Enviar',
                tipo: CustomButtonType.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _obtenerTextoCalificacion() {
    switch (_calificacion) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return '¡Excelente!';
      default:
        return '';
    }
  }
}
