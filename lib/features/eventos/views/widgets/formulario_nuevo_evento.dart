import 'dart:io';

import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_text_field.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/categoria_viewmodel.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/widgets/componentes_formulario_evento.dart';
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
      final archivo = File(imagen.path);
      final esValido = await validarTamanoImagen(
        context,
        archivo,
        esFlyer: esFlyer,
      );

      if (esValido) {
        setState(() {
          if (esFlyer) {
            _flyerSeleccionado = archivo;
          } else {
            _imagenSeleccionada = archivo;
          }
        });
      }
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
      setState(() => _errorCategorias = 'Selecciona al menos una categoría');
    }

    // Valida el formulario.
    if (!_formKey.currentState!.validate() ||
        _categoriasSeleccionadas.isEmpty) {
      return;
    }

    // Obtiene el id del organizador.
    final perfil = ref.read(perfilActualProvider);
    if (perfil == null) {
      _mostrarError('No se pudo obtener el perfil del usuario');
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

      final exito =
          await ref.read(crearEventoProvider.notifier).crearEvento(
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
        final estado = ref.read(crearEventoProvider);
        if (estado is CrearEventoExitoso) {
          ref
              .read(eventosOrganizadorProvider.notifier)
              .agregarEvento(estado.evento);
        }
        _mostrarExito('Evento creado exitosamente');
        widget.onGuardar?.call();
      } else if (mounted) {
        final estado = ref.read(crearEventoProvider);
        if (estado is CrearEventoError) {
          _mostrarError(estado.mensaje);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al crear evento: $e');
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
    final categorias = ref.watch(listaCategoriasCacheProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      texto: _fechaEvento != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaEvento!)
                          : 'Seleccionar fecha',
                      onTap: _seleccionarFecha,
                      mostrarError: _fechaEvento == null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectorFechaHora(
                      icono: Icons.access_time,
                      texto: _horaEvento != null
                          ? formatearHora24(_horaEvento!)
                          : 'Seleccionar hora',
                      onTap: _seleccionarHora,
                      mostrarError: _horaEvento == null,
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
              child: SelectorImagenNueva(
                imagen: _imagenSeleccionada,
                esFlyer: false,
                onSeleccionar: () => _seleccionarImagen(esFlyer: false),
                onEliminar: () => _eliminarImagen(esFlyer: false),
              ),
            ),

            // Flyer del evento.
            SeccionFormulario(
              titulo: 'Flyer del evento',
              obligatorio: false,
              child: SelectorImagenNueva(
                imagen: _flyerSeleccionado,
                esFlyer: true,
                onSeleccionar: () => _seleccionarImagen(esFlyer: true),
                onEliminar: () => _eliminarImagen(esFlyer: true),
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
}
