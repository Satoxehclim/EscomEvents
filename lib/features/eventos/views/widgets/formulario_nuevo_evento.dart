import 'dart:io';

import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_text_field.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/categoria_viewmodel.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Formulario para crear un nuevo evento.
//
// Incluye campos para nombre, fecha, lugar, descripción, entrada libre,
// selección de imagen y flyer, y selector de categorías.
class FormularioNuevoEvento extends ConsumerStatefulWidget {
  // Callback cuando se guarda el evento.
  final VoidCallback? onGuardar;

  // Callback cuando se cancela.
  final VoidCallback? onCancelar;

  const FormularioNuevoEvento({
    super.key,
    this.onGuardar,
    this.onCancelar,
  });

  @override
  ConsumerState<FormularioNuevoEvento> createState() =>
      _FormularioNuevoEventoState();
}

class _FormularioNuevoEventoState extends ConsumerState<FormularioNuevoEvento> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controladores de texto.
  final _nombreController = TextEditingController();
  final _lugarController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Estado del formulario.
  DateTime? _fechaEvento;
  TimeOfDay? _horaEvento;
  bool _entradaLibre = true;
  File? _imagenSeleccionada;
  File? _flyerSeleccionado;
  List<CategoriaModel> _categoriasSeleccionadas = [];
  bool _guardando = false;

  // Error de validación para categorías.
  String? _errorCategorias;

  @override
  void dispose() {
    _nombreController.dispose();
    _lugarController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // Selecciona una fecha.
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEvento ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() => _fechaEvento = fecha);
    }
  }

  // Selecciona una hora.
  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaEvento ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() => _horaEvento = hora);
    }
  }

  // Formatea la hora en formato de 24 horas (HH:mm).
  String _formatearHora24(TimeOfDay hora) {
    final horaStr = hora.hour.toString().padLeft(2, '0');
    final minutoStr = hora.minute.toString().padLeft(2, '0');
    return '$horaStr:$minutoStr';
  }

  // Selecciona una imagen desde galería o cámara.
  Future<void> _seleccionarImagen({required bool esFlyer}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final opcion = await showModalBottomSheet<ImageSource>(
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

    if (opcion == null) return;

    final imagen = await _imagePicker.pickImage(
      source: opcion,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (imagen != null) {
      // Valida el tamaño del archivo.
      final archivo = File(imagen.path);
      final tamanoBytes = await archivo.length();
      final tamanoMB = tamanoBytes / (1024 * 1024);

      // Límite: 5 MB para flyer, 1 MB para imagen.
      final limiteMaxMB = esFlyer ? 5.0 : 1.0;

      if (tamanoMB > limiteMaxMB) {
        if (mounted) {
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
        return;
      }

      setState(() {
        if (esFlyer) {
          _flyerSeleccionado = archivo;
        } else {
          _imagenSeleccionada = archivo;
        }
      });
    }
  }

  // Elimina una imagen seleccionada.
  void _eliminarImagen({required bool esFlyer}) {
    setState(() {
      if (esFlyer) {
        _flyerSeleccionado = null;
      } else {
        _imagenSeleccionada = null;
      }
    });
  }

  // Alterna la selección de una categoría.
  void _alternarCategoria(CategoriaModel categoria) {
    setState(() {
      if (_categoriasSeleccionadas.contains(categoria)) {
        _categoriasSeleccionadas.remove(categoria);
      } else {
        _categoriasSeleccionadas.add(categoria);
      }
      // Limpia el error si ya hay categorías seleccionadas.
      if (_categoriasSeleccionadas.isNotEmpty) {
        _errorCategorias = null;
      }
    });
  }

  // Valida y guarda el formulario.
  Future<void> _guardar() async {
    // Valida las categorías.
    if (_categoriasSeleccionadas.isEmpty) {
      setState(() {
        _errorCategorias = 'Selecciona al menos una categoría';
      });
    }

    // Valida el formulario.
    if (!_formKey.currentState!.validate() ||
        _categoriasSeleccionadas.isEmpty) {
      return;
    }

    // Obtiene el id del organizador.
    final perfil = ref.read(perfilActualProvider);
    if (perfil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el perfil del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      // Combina fecha y hora.
      final fechaCompleta = DateTime(
        _fechaEvento!.year,
        _fechaEvento!.month,
        _fechaEvento!.day,
        _horaEvento?.hour ?? 0,
        _horaEvento?.minute ?? 0,
      );

      // Crea el evento usando el viewmodel.
      final exito = await ref.read(crearEventoProvider.notifier).crearEvento(
            idOrganizador: perfil.idPerfil,
            nombre: _nombreController.text.trim(),
            fecha: fechaCompleta,
            lugar: _lugarController.text.trim(),
            entradaLibre: _entradaLibre,
            descripcion: _descripcionController.text.trim().isNotEmpty
                ? _descripcionController.text.trim()
                : null,
            imagen: _imagenSeleccionada,
            flyer: _flyerSeleccionado,
            categorias: _categoriasSeleccionadas,
          );

      if (exito && mounted) {
        // Agrega el evento a la lista del organizador.
        final estadoCrear = ref.read(crearEventoProvider);
        if (estadoCrear is CrearEventoExitoso) {
          ref
              .read(eventosOrganizadorProvider.notifier)
              .agregarEvento(estadoCrear.evento);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGuardar?.call();
      } else if (mounted) {
        final estadoError = ref.read(crearEventoProvider);
        if (estadoError is CrearEventoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${estadoError.mensaje}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear evento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categorias = ref.watch(listaCategoriasCacheProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo: Nombre del evento (obligatorio).
            _construirSeccion(
              titulo: 'Nombre del evento',
              obligatorio: true,
              child: CustomTextField(
                controller: _nombreController,
                hintText: 'Ej: Hackathon 2026',
                prefixIcon: Icons.event,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (valor.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
            ),

            // Campo: Fecha y hora (obligatorio).
            _construirSeccion(
              titulo: 'Fecha y hora',
              obligatorio: true,
              child: Row(
                children: [
                  // Selector de fecha.
                  Expanded(
                    child: _construirSelectorFechaHora(
                      icono: Icons.calendar_today,
                      texto: _fechaEvento != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaEvento!)
                          : 'Seleccionar fecha',
                      onTap: _seleccionarFecha,
                      error: _fechaEvento == null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selector de hora.
                  Expanded(
                    child: _construirSelectorFechaHora(
                      icono: Icons.access_time,
                      texto: _horaEvento != null
                          ? _formatearHora24(_horaEvento!)
                          : 'Seleccionar hora',
                      onTap: _seleccionarHora,
                      error: _horaEvento == null,
                    ),
                  ),
                ],
              ),
            ),

            // Campo: Lugar (obligatorio).
            _construirSeccion(
              titulo: 'Lugar',
              obligatorio: true,
              child: CustomTextField(
                controller: _lugarController,
                hintText: 'Ej: Auditorio A',
                prefixIcon: Icons.location_on,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El lugar es obligatorio';
                  }
                  return null;
                },
              ),
            ),

            // Campo: Descripción (opcional).
            _construirSeccion(
              titulo: 'Descripción',
              obligatorio: false,
              child: CustomTextField(
                controller: _descripcionController,
                hintText: 'Describe el evento...',
                prefixIcon: Icons.description,
                maxLines: 5,
                minLines: 3,
              ),
            ),

            // Campo: Entrada libre.
            _construirSeccion(
              titulo: 'Tipo de entrada',
              obligatorio: true,
              child: _construirSwitchEntradaLibre(isDark),
            ),

            // Campo: Imagen del evento (opcional).
            _construirSeccion(
              titulo: 'Imagen del evento',
              obligatorio: false,
              child: _construirSelectorImagen(
                imagen: _imagenSeleccionada,
                esFlyer: false,
                isDark: isDark,
              ),
            ),

            // Campo: Flyer del evento (opcional).
            _construirSeccion(
              titulo: 'Flyer del evento',
              obligatorio: false,
              child: _construirSelectorImagen(
                imagen: _flyerSeleccionado,
                esFlyer: true,
                isDark: isDark,
              ),
            ),

            // Campo: Categorías (obligatorio).
            _construirSeccion(
              titulo: 'Categorías',
              obligatorio: true,
              child: _construirSelectorCategorias(categorias, isDark),
            ),

            const SizedBox(height: 24),

            // Botones de acción.
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    texto: 'Cancelar',
                    tipo: CustomButtonType.outlined,
                    onPressed: _guardando ? null : widget.onCancelar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    texto: 'Crear Evento',
                    tipo: CustomButtonType.primary,
                    cargando: _guardando,
                    onPressed: _guardando ? null : _guardar,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Construye una sección con título.
  Widget _construirSeccion({
    required String titulo,
    required bool obligatorio,
    required Widget child,
  }) {
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

  // Construye el selector de fecha/hora.
  Widget _construirSelectorFechaHora({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    required bool error,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: error
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
                  color: texto.contains('Seleccionar')
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

  // Construye el switch de entrada libre.
  Widget _construirSwitchEntradaLibre(bool isDark) {
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
            _entradaLibre ? Icons.lock_open : Icons.lock,
            color: Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _entradaLibre ? 'Entrada libre' : 'Evento con control de acceso',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Switch(
            value: _entradaLibre,
            onChanged: (valor) => setState(() => _entradaLibre = valor),
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  // Construye el selector de imagen.
  Widget _construirSelectorImagen({
    required File? imagen,
    required bool esFlyer,
    required bool isDark,
  }) {
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
              imagen,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => _eliminarImagen(esFlyer: esFlyer),
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
      onTap: () => _seleccionarImagen(esFlyer: esFlyer),
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
            style: BorderStyle.solid,
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
                    : 'Agrega una imagen representativa del evento (recomendada 360x150, máx. 1 MB)',
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

  // Construye el selector de categorías.
  Widget _construirSelectorCategorias(
    List<CategoriaModel> categorias,
    bool isDark,
  ) {
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
            border: _errorCategorias != null
                ? Border.all(color: Colors.red.shade300, width: 1)
                : null,
          ),
          child: categorias.isEmpty
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
                  children: categorias.map((categoria) {
                    final seleccionada =
                        _categoriasSeleccionadas.contains(categoria);
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
                      onSelected: (_) => _alternarCategoria(categoria),
                    );
                  }).toList(),
                ),
        ),
        if (_errorCategorias != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              _errorCategorias!,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
          ),
        if (_categoriasSeleccionadas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_categoriasSeleccionadas.length} categoría(s) seleccionada(s)',
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
