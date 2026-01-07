import 'dart:io';

import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_text_field.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/categoria_viewmodel.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/widgets/componentes_formulario_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Formulario para editar un evento existente.
//
// Muestra los datos actuales del evento y permite modificarlos.
// Implementa mecanismos de rollback en caso de error.
class FormularioEditarEvento extends ConsumerStatefulWidget {
  // Evento a editar.
  final EventModel evento;

  // Callback cuando se guarda el evento.
  final void Function(EventModel eventoActualizado)? onGuardar;

  // Callback cuando se cancela.
  final VoidCallback? onCancelar;

  const FormularioEditarEvento({
    super.key,
    required this.evento,
    this.onGuardar,
    this.onCancelar,
  });

  @override
  ConsumerState<FormularioEditarEvento> createState() =>
      _FormularioEditarEventoState();
}

class _FormularioEditarEventoState
    extends ConsumerState<FormularioEditarEvento> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controladores de texto.
  late final TextEditingController _nombreController;
  late final TextEditingController _lugarController;
  late final TextEditingController _descripcionController;

  // Estado del formulario.
  late DateTime _fechaEvento;
  late TimeOfDay _horaEvento;
  late bool _entradaLibre;
  late List<CategoriaModel> _categoriasSeleccionadas;

  // Imágenes.
  File? _nuevaImagen;
  File? _nuevoFlyer;
  bool _eliminarImagenActual = false;
  bool _eliminarFlyerActual = false;

  // Estado de carga.
  bool _guardando = false;

  // Error de validación para categorías.
  String? _errorCategorias;

  @override
  void initState() {
    super.initState();

    // Inicializa los controladores con los valores del evento.
    _nombreController = TextEditingController(text: widget.evento.nombre);
    _lugarController = TextEditingController(text: widget.evento.lugar);
    _descripcionController =
        TextEditingController(text: widget.evento.descripcion ?? '');

    // Inicializa los valores de fecha/hora.
    _fechaEvento = widget.evento.fecha;
    _horaEvento = TimeOfDay(
      hour: widget.evento.fecha.hour,
      minute: widget.evento.fecha.minute,
    );

    // Inicializa otros valores.
    _entradaLibre = widget.evento.entradaLibre;
    _categoriasSeleccionadas = List.from(widget.evento.categorias);
  }

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
      initialDate: _fechaEvento,
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
      initialTime: _horaEvento,
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

  Future<void> _seleccionarImagen({required bool esFlyer}) async {
    final opcion = await mostrarSelectorOrigenImagen(context, esFlyer: esFlyer);
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
      final esValido = await validarTamanoImagen(
        context,
        archivo,
        esFlyer: esFlyer,
      );

      if (esValido) {
        setState(() {
          if (esFlyer) {
            _nuevoFlyer = archivo;
            _eliminarFlyerActual = false;
          } else {
            _nuevaImagen = archivo;
            _eliminarImagenActual = false;
          }
        });
      }
    }
  }

  // Elimina una imagen.
  void _eliminarImagen({required bool esFlyer}) {
    setState(() {
      if (esFlyer) {
        _nuevoFlyer = null;
        _eliminarFlyerActual = true;
      } else {
        _nuevaImagen = null;
        _eliminarImagenActual = true;
      }
    });
  }

  // Restaura la imagen original.
  void _restaurarImagen({required bool esFlyer}) {
    setState(() {
      if (esFlyer) {
        _nuevoFlyer = null;
        _eliminarFlyerActual = false;
      } else {
        _nuevaImagen = null;
        _eliminarImagenActual = false;
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
      if (_categoriasSeleccionadas.isNotEmpty) {
        _errorCategorias = null;
      }
    });
  }

  // Valida y guarda los cambios.
  Future<void> _guardar() async {
    // Valida las categorías.
    if (_categoriasSeleccionadas.isEmpty) {
      setState(() => _errorCategorias = 'Selecciona al menos una categoría');
    }

    // Valida el formulario.
    if (!_formKey.currentState!.validate() ||
        _categoriasSeleccionadas.isEmpty) {
      return;
    }

    setState(() => _guardando = true);

    try {
      // Combina fecha y hora.
      final fechaCompleta = DateTime(
        _fechaEvento.year,
        _fechaEvento.month,
        _fechaEvento.day,
        _horaEvento.hour,
        _horaEvento.minute,
      );

      // Determina si el evento estaba en estado "En Corrección".
      // Si tiene comentario_admin y no está validado, al guardar limpiamos el comentario.
      final estaEnCorreccion = widget.evento.comentarioAdmin != null &&
          widget.evento.comentarioAdmin!.isNotEmpty &&
          widget.evento.validado == false;

      // Actualiza el evento usando el viewmodel.
      final eventoActualizado =
          await ref.read(editarEventoProvider.notifier).actualizarEvento(
                eventoOriginal: widget.evento,
                nombre: _nombreController.text.trim(),
                fecha: fechaCompleta,
                lugar: _lugarController.text.trim(),
                entradaLibre: _entradaLibre,
                descripcion: _descripcionController.text.trim().isNotEmpty
                    ? _descripcionController.text.trim()
                    : null,
                nuevaImagen: _nuevaImagen,
                nuevoFlyer: _nuevoFlyer,
                eliminarImagen: _eliminarImagenActual,
                eliminarFlyer: _eliminarFlyerActual,
                categorias: _categoriasSeleccionadas,
                limpiarComentarioAdmin: estaEnCorreccion,
              );

      if (eventoActualizado != null && mounted) {
        // Actualiza la lista del organizador.
        ref
            .read(eventosOrganizadorProvider.notifier)
            .actualizarEvento(eventoActualizado);
        _mostrarExito('Evento actualizado exitosamente');
        widget.onGuardar?.call(eventoActualizado);
      } else if (mounted) {
        final estado = ref.read(editarEventoProvider);
        if (estado is EditarEventoError) {
          _mostrarError(estado.mensaje);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar evento: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categorias = ref.watch(listaCategoriasCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Evento',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del evento.
              SeccionFormulario(
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

              // Fecha y hora.
              SeccionFormulario(
                titulo: 'Fecha y hora',
                obligatorio: true,
                child: Row(
                  children: [
                    Expanded(
                      child: SelectorFechaHora(
                        icono: Icons.calendar_today,
                        texto: DateFormat('dd/MM/yyyy').format(_fechaEvento),
                        onTap: _seleccionarFecha,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectorFechaHora(
                        icono: Icons.access_time,
                        texto: formatearHora24(_horaEvento),
                        onTap: _seleccionarHora,
                      ),
                    ),
                  ],
                ),
              ),

              // Lugar.
              SeccionFormulario(
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

              // Descripción.
              SeccionFormulario(
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

              // Tipo de entrada.
              SeccionFormulario(
                titulo: 'Tipo de entrada',
                obligatorio: true,
                child: SwitchEntradaLibre(
                  valor: _entradaLibre,
                  onChanged: (valor) => setState(() => _entradaLibre = valor),
                ),
              ),

              // Imagen del evento.
              SeccionFormulario(
                titulo: 'Imagen del evento',
                obligatorio: false,
                child: SelectorImagenEdicion(
                  imagenActualUrl: widget.evento.imageUrl,
                  nuevaImagen: _nuevaImagen,
                  eliminada: _eliminarImagenActual,
                  esFlyer: false,
                  onSeleccionar: () => _seleccionarImagen(esFlyer: false),
                  onEliminar: () => _eliminarImagen(esFlyer: false),
                  onRestaurar: () => _restaurarImagen(esFlyer: false),
                ),
              ),

              // Flyer del evento.
              SeccionFormulario(
                titulo: 'Flyer del evento',
                obligatorio: false,
                child: SelectorImagenEdicion(
                  imagenActualUrl: widget.evento.flyer,
                  nuevaImagen: _nuevoFlyer,
                  eliminada: _eliminarFlyerActual,
                  esFlyer: true,
                  onSeleccionar: () => _seleccionarImagen(esFlyer: true),
                  onEliminar: () => _eliminarImagen(esFlyer: true),
                  onRestaurar: () => _restaurarImagen(esFlyer: true),
                ),
              ),

              // Categorías.
              SeccionFormulario(
                titulo: 'Categorías',
                obligatorio: true,
                child: SelectorCategorias(
                  categoriasDisponibles: categorias,
                  categoriasSeleccionadas: _categoriasSeleccionadas,
                  errorMensaje: _errorCategorias,
                  onCategoriaSeleccionada: _alternarCategoria,
                ),
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
                      texto: 'Guardar Cambios',
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
      ),
    );
  }
}
