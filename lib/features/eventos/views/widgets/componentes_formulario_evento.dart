import 'dart:io';

import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ============================================================
// Utilidades
// ============================================================

// Formatea una hora en formato de 24 horas (HH:mm).
String formatearHora24(TimeOfDay hora) {
  final horaStr = hora.hour.toString().padLeft(2, '0');
  final minutoStr = hora.minute.toString().padLeft(2, '0');
  return '$horaStr:$minutoStr';
}

// Muestra el selector de origen de imagen (galería o cámara).
Future<ImageSource?> mostrarSelectorOrigenImagen(
  BuildContext context, {
  required bool esFlyer,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                esFlyer ? 'Seleccionar Flyer' : 'Seleccionar Imagen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Valida el tamaño de un archivo de imagen.
// Retorna true si es válido, false si excede el límite.
Future<bool> validarTamanoImagen(
  BuildContext context,
  File archivo, {
  required bool esFlyer,
}) async {
  final tamanoBytes = await archivo.length();
  final tamanoMB = tamanoBytes / (1024 * 1024);
  final limiteMaxMB = esFlyer ? 5.0 : 1.0;

  if (tamanoMB > limiteMaxMB) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esFlyer
                ? 'El flyer excede el límite de 5 MB (${tamanoMB.toStringAsFixed(2)} MB)'
                : 'La imagen excede el límite de 1 MB (${tamanoMB.toStringAsFixed(2)} MB)',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
  return true;
}

// ============================================================
// Widgets compartidos
// ============================================================

// Sección con título para campos del formulario.
class SeccionFormulario extends StatelessWidget {
  final String titulo;
  final bool obligatorio;
  final Widget child;

  const SeccionFormulario({
    super.key,
    required this.titulo,
    required this.obligatorio,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (obligatorio)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Selector de fecha u hora.
class SelectorFechaHora extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final bool mostrarError;

  const SelectorFechaHora({
    super.key,
    required this.icono,
    required this.texto,
    required this.onTap,
    this.mostrarError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final esPlaceholder = texto.contains('Seleccionar');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: mostrarError
              ? Border.all(color: Colors.red.shade300, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icono, color: Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: esPlaceholder
                      ? Colors.grey.withOpacity(0.7)
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Switch para entrada libre.
class SwitchEntradaLibre extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;

  const SwitchEntradaLibre({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            valor ? Icons.lock_open : Icons.lock,
            color: Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor ? 'Entrada libre' : 'Evento con control de acceso',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Switch(
            value: valor,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}

// Selector de imagen para crear eventos (sin imagen previa del servidor).
class SelectorImagenNueva extends StatelessWidget {
  final File? imagen;
  final bool esFlyer;
  final VoidCallback onSeleccionar;
  final VoidCallback onEliminar;

  const SelectorImagenNueva({
    super.key,
    required this.imagen,
    required this.esFlyer,
    required this.onSeleccionar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    if (imagen != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imagen!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onEliminar,
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onSeleccionar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                esFlyer ? Icons.insert_drive_file : Icons.add_photo_alternate,
                size: 40,
                color: primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 8),
              Text(
                esFlyer
                    ? 'Agrega el flyer (máx. 5 MB)'
                    : 'Agrega una imagen (máx. 1 MB)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Selector de imagen para editar eventos (con imagen previa del servidor).
class SelectorImagenEdicion extends StatelessWidget {
  final String? imagenActualUrl;
  final File? nuevaImagen;
  final bool eliminada;
  final bool esFlyer;
  final VoidCallback onSeleccionar;
  final VoidCallback onEliminar;
  final VoidCallback? onRestaurar;

  const SelectorImagenEdicion({
    super.key,
    required this.imagenActualUrl,
    required this.nuevaImagen,
    required this.eliminada,
    required this.esFlyer,
    required this.onSeleccionar,
    required this.onEliminar,
    this.onRestaurar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    // Si hay una nueva imagen seleccionada.
    if (nuevaImagen != null) {
      return _construirVistaImagenNueva(
        context,
        nuevaImagen!,
        primaryColor,
      );
    }

    // Si la imagen fue eliminada.
    if (eliminada) {
      return _construirVistaImagenEliminada(
        context,
        backgroundColor,
      );
    }

    // Si hay imagen actual del servidor.
    if (imagenActualUrl != null && imagenActualUrl!.isNotEmpty) {
      return _construirVistaImagenActual(
        context,
        imagenActualUrl!,
        primaryColor,
        backgroundColor,
      );
    }

    // Sin imagen (permite agregar).
    return _construirVistaVacia(
      context,
      primaryColor,
      backgroundColor,
    );
  }

  Widget _construirVistaImagenNueva(
    BuildContext context,
    File imagen,
    Color primaryColor,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            imagen,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              if (imagenActualUrl != null && onRestaurar != null)
                IconButton(
                  onPressed: onRestaurar,
                  icon: const Icon(Icons.restore),
                  tooltip: 'Restaurar original',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Nueva',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirVistaImagenEliminada(
    BuildContext context,
    Color backgroundColor,
  ) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 40,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          const Text(
            'Imagen eliminada',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagenActualUrl != null && onRestaurar != null)
                TextButton.icon(
                  onPressed: onRestaurar,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar'),
                ),
              TextButton.icon(
                onPressed: onSeleccionar,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Nueva imagen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirVistaImagenActual(
    BuildContext context,
    String url,
    Color primaryColor,
    Color backgroundColor,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              IconButton(
                onPressed: onSeleccionar,
                icon: const Icon(Icons.edit),
                tooltip: 'Cambiar imagen',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete),
                tooltip: 'Eliminar imagen',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Actual',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirVistaVacia(
    BuildContext context,
    Color primaryColor,
    Color backgroundColor,
  ) {
    return InkWell(
      onTap: onSeleccionar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                esFlyer ? Icons.insert_drive_file : Icons.add_photo_alternate,
                size: 40,
                color: primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 8),
              Text(
                esFlyer
                    ? 'Agrega el flyer (máx. 5 MB)'
                    : 'Agrega una imagen (máx. 1 MB)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Selector de categorías.
class SelectorCategorias extends StatelessWidget {
  final List<CategoriaModel> categoriasDisponibles;
  final List<CategoriaModel> categoriasSeleccionadas;
  final String? errorMensaje;
  final ValueChanged<CategoriaModel> onCategoriaSeleccionada;

  const SelectorCategorias({
    super.key,
    required this.categoriasDisponibles,
    required this.categoriasSeleccionadas,
    this.errorMensaje,
    required this.onCategoriaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: errorMensaje != null
                ? Border.all(color: Colors.red.shade300, width: 1)
                : null,
          ),
          child: categoriasDisponibles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay categorías disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoriasDisponibles.map((categoria) {
                    final seleccionada =
                        categoriasSeleccionadas.contains(categoria);
                    return FilterChip(
                      selected: seleccionada,
                      label: Text(categoria.nombre),
                      avatar: Icon(
                        categoria.icono ?? Icons.category,
                        size: 18,
                        color: seleccionada ? Colors.white : primaryColor,
                      ),
                      selectedColor: primaryColor,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: seleccionada ? Colors.white : primaryColor,
                        fontWeight:
                            seleccionada ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: primaryColor),
                      onSelected: (_) => onCategoriaSeleccionada(categoria),
                    );
                  }).toList(),
                ),
        ),
        if (errorMensaje != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorMensaje!,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
          ),
        if (categoriasSeleccionadas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${categoriasSeleccionadas.length} categoría(s) seleccionada(s)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
