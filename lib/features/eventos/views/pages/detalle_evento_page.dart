import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/widgets/detalle_evento_widgets.dart';
import 'package:escomevents_app/features/eventos/views/widgets/formulario_editar_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Origen desde donde se navega al detalle del evento.
enum OrigenDetalle {
  misEventos,
  eventos,
}

// Página que muestra los detalles completos de un evento.
class DetalleEventoPage extends ConsumerStatefulWidget {
  final EventModel evento;
  final RolUsuario rol;
  final OrigenDetalle origen;
  final String? nombreOrganizador;
  // Callback para cuando el evento sea actualizado.
  final void Function(EventModel eventoActualizado)? onEventoActualizado;
  // Callback para cuando el evento sea eliminado.
  final VoidCallback? onEventoEliminado;

  const DetalleEventoPage({
    super.key,
    required this.evento,
    required this.rol,
    this.origen = OrigenDetalle.eventos,
    this.nombreOrganizador,
    this.onEventoActualizado,
    this.onEventoEliminado,
  });

  @override
  ConsumerState<DetalleEventoPage> createState() => _DetalleEventoPageState();
}

class _DetalleEventoPageState extends ConsumerState<DetalleEventoPage> {
  // Evento actual (puede actualizarse después de editar).
  late EventModel _eventoActual;

  @override
  void initState() {
    super.initState();
    _eventoActual = widget.evento;
  }

  // Determina si el usuario puede editar el evento.
  bool get _puedeEditar {
    // Solo el organizador puede editar sus propios eventos.
    // o el admin puede editar cualquiera.
    if (widget.rol == RolUsuario.administrador) return true;
    if (widget.rol == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra el estado de validación.
  bool get _mostrarValidado {
    if (widget.rol == RolUsuario.administrador) return true;
    if (widget.rol == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra created_at.
  bool get _mostrarCreatedAt {
    if (widget.rol == RolUsuario.administrador) return true;
    if (widget.rol == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra la información administrativa.
  bool get _mostrarInfoAdministrativa => _mostrarValidado || _mostrarCreatedAt;

  // Determina si se muestra el comentario del administrador.
  bool get _mostrarComentarioAdmin {
    if (widget.rol != RolUsuario.administrador &&
        widget.rol != RolUsuario.organizador) {
      return false;
    }
    final comentario = _eventoActual.comentarioAdmin;
    return comentario != null && comentario.isNotEmpty;
  }

  // Determina si se muestran las acciones de administrador.
  bool get _mostrarAccionesAdmin {
    if (widget.rol != RolUsuario.administrador) return false;
    // Solo mostrar acciones si el evento está pendiente de validación.
    return _eventoActual.validado == false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen.
          DetalleEventoAppBar(
            evento: _eventoActual,
            onBack: () => Navigator.of(context).pop(),
          ),

          // Contenido.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del evento y menú de opciones.
                  _construirEncabezado(theme),
                  const SizedBox(height: 16),

                  // Categorías.
                  if (_eventoActual.categorias.isNotEmpty)
                    ChipsCategorias(categorias: _eventoActual.categorias),

                  // Información del organizador.
                  if (widget.nombreOrganizador != null) ...[
                    const SizedBox(height: 20),
                    InfoOrganizador(
                      nombreOrganizador: widget.nombreOrganizador!,
                    ),
                  ],

                  // Detalles principales.
                  const SizedBox(height: 20),
                  DetallesPrincipales(evento: _eventoActual),

                  // Descripción.
                  if (_eventoActual.descripcion != null &&
                      _eventoActual.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SeccionConTitulo(
                      titulo: 'Descripción',
                      child: Text(
                        _eventoActual.descripcion!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // Resumen de comentarios.
                  if (_eventoActual.resumenComentarios != null &&
                      _eventoActual.resumenComentarios!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SeccionConTitulo(
                      titulo: 'Resumen de comentarios',
                      child: Text(
                        _eventoActual.resumenComentarios!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  // Flyer.
                  if (_eventoActual.flyer != null &&
                      _eventoActual.flyer!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SeccionConTitulo(
                      titulo: 'Flyer del evento',
                      child: FlyerEvento(flyerUrl: _eventoActual.flyer!),
                    ),
                  ],

                  // Información administrativa.
                  if (_mostrarInfoAdministrativa) ...[
                    const SizedBox(height: 24),
                    InfoAdministrativa(
                      evento: _eventoActual,
                      mostrarValidado: _mostrarValidado,
                      mostrarCreatedAt: _mostrarCreatedAt,
                      mostrarIdEvento:
                          widget.rol == RolUsuario.administrador,
                    ),
                  ],

                  // Comentario del admin.
                  if (_mostrarComentarioAdmin) ...[
                    const SizedBox(height: 24),
                    ComentarioAdmin(
                      comentario: _eventoActual.comentarioAdmin!,
                    ),
                  ],

                  // Acciones de administrador.
                  if (_mostrarAccionesAdmin) ...[
                    const SizedBox(height: 24),
                    AccionesAdmin(
                      onAprobar: _aprobarEvento,
                      onRechazar: _mostrarDialogoRechazo,
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el encabezado con nombre y menú.
  Widget _construirEncabezado(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _eventoActual.nombre,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_puedeEditar)
          MenuOpcionesEvento(
            onEditar: _abrirFormularioEdicion,
            onEliminar: _mostrarDialogoEliminar,
          ),
      ],
    );
  }

  // Abre el formulario de edición del evento.
  void _abrirFormularioEdicion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormularioEditarEvento(
          evento: _eventoActual,
          onGuardar: (eventoActualizado) {
            setState(() {
              _eventoActual = eventoActualizado;
            });
            widget.onEventoActualizado?.call(eventoActualizado);
            Navigator.of(context).pop();
          },
          onCancelar: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Muestra el diálogo de confirmación para eliminar.
  void _mostrarDialogoEliminar() {
    DialogoEliminarEvento.mostrar(
      context: context,
      nombreEvento: _eventoActual.nombre,
      onConfirmar: () {
        widget.onEventoEliminado?.call();
        Navigator.of(context).pop();
      },
    );
  }

  // Muestra el diálogo para rechazar el evento.
  void _mostrarDialogoRechazo() {
    DialogoRechazarEvento.mostrar(
      context: context,
      onRechazar: _rechazarEvento,
    );
  }

  // Aprueba el evento.
  Future<void> _aprobarEvento() async {
    final notifier = ref.read(validarEventoProvider.notifier);
    final evento = await notifier.aprobarEvento(_eventoActual.id);

    if (!mounted) return;

    if (evento != null) {
      ref.read(eventosAdminProvider.notifier).recargar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento aprobado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _mostrarErrorValidacion('aprobar');
    }
  }

  // Rechaza el evento con el comentario indicado.
  Future<void> _rechazarEvento(String comentario) async {
    final notifier = ref.read(validarEventoProvider.notifier);
    final evento = await notifier.rechazarEvento(_eventoActual.id, comentario);

    if (!mounted) return;

    if (evento != null) {
      ref.read(eventosAdminProvider.notifier).recargar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento rechazado correctamente'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _mostrarErrorValidacion('rechazar');
    }
  }

  // Muestra un error de validación.
  void _mostrarErrorValidacion(String accion) {
    final state = ref.read(validarEventoProvider);
    if (state is ValidarEventoError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al $accion: ${state.mensaje}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
