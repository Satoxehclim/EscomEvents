import 'package:escomevents_app/features/home/models/perfil_model.dart';
import 'package:escomevents_app/features/home/views/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/viewmodel/asistencia_viewmodel.dart';
import 'package:escomevents_app/features/eventos/viewmodel/calificacion_viewmodel.dart';
import 'package:escomevents_app/features/eventos/viewmodel/evento_viewmodel.dart';
import 'package:escomevents_app/features/eventos/views/pages/calificaciones_evento_page.dart';
import 'package:escomevents_app/features/eventos/views/pages/lista_asistentes_page.dart';
import 'package:escomevents_app/features/eventos/views/widgets/detalle_evento_widgets.dart';
import 'package:escomevents_app/features/eventos/views/widgets/dialogo_calificar_evento.dart';
import 'package:escomevents_app/features/eventos/views/widgets/escaner_asistencia.dart';
import 'package:escomevents_app/features/eventos/views/widgets/formulario_editar_evento.dart';
import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Origen desde donde se navega al detalle del evento.
enum OrigenDetalle {
  misEventos,
  eventos,
  misEventosEstudiante,
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
    // Verifica asistencia y calificación si es estudiante.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = ref.read(perfilActualProvider);
      if (perfil?.rol == RolUsuario.estudiante) {
        _verificarAsistencia();
        _verificarCalificacion();
      }
    });
  }

  // Verifica si el estudiante está registrado al evento.
  void _verificarAsistencia() {
    final perfil = ref.read(perfilActualProvider);
    if (perfil != null) {
      ref.read(asistenciaProvider.notifier).verificarAsistencia(
            idPerfil: perfil.idPerfil,
            idEvento: _eventoActual.id,
          );
    }
  }

  // Verifica si el estudiante ya calificó el evento.
  void _verificarCalificacion() {
    final perfil = ref.read(perfilActualProvider);
    if (perfil != null) {
      ref.read(calificacionEstudianteProvider.notifier).verificarCalificacion(
            idPerfil: perfil.idPerfil,
            idEvento: _eventoActual.id,
          );
    }
  }

  // Determina si el evento ya pasó.
  bool get _eventoYaPaso => _eventoActual.fecha.isBefore(DateTime.now());

  // Determina si ya se le pasó asistencia al estudiante.
  bool _yaSeLeMarcoAsistencia(AsistenciaEventoState estado) {
    if (estado is AsistenciaEventoRegistrado) {
      // Si asistio es 1, ya se le marcó asistencia.
      return (estado.asistencia.asistio == 1);
    }
    return false;
  }

  // Determina si el botón de asistencia debe mostrarse.
  bool get _mostrarBotonAsistencia {
    final perfil = ref.read(perfilActualProvider);
    if (perfil?.rol != RolUsuario.estudiante) return false;

    // No mostrar si el evento ya pasó.
    if (_eventoYaPaso) return false;

    // No mostrar si el evento está cancelado.
    if (_eventoActual.cancelado) return false;

    return true;
  }

  // Obtiene el rol actual del usuario.
  RolUsuario? get _rolActual => ref.read(perfilActualProvider)?.rol;

  // Determina si el usuario puede editar el evento.
  bool get _puedeEditar {
    // Solo el organizador puede editar sus propios eventos.
    // o el admin puede editar cualquiera.
    if (_rolActual == RolUsuario.administrador) return true;
    if (_rolActual == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra el estado de validación.
  bool get _mostrarValidado {
    if (_rolActual == RolUsuario.administrador) return true;
    if (_rolActual == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra created_at.
  bool get _mostrarCreatedAt {
    if (_rolActual == RolUsuario.administrador) return true;
    if (_rolActual == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos) {
      return true;
    }
    return false;
  }

  // Determina si se muestra la información administrativa.
  bool get _mostrarInfoAdministrativa => _mostrarValidado || _mostrarCreatedAt;

  // Determina si se muestra el comentario del administrador.
  bool get _mostrarComentarioAdmin {
    if (_rolActual != RolUsuario.administrador &&
        _rolActual != RolUsuario.organizador) {
      return false;
    }
    final comentario = _eventoActual.comentarioAdmin;
    return comentario != null && comentario.isNotEmpty;
  }

  // Determina si se muestran las acciones de administrador.
  bool get _mostrarAccionesAdmin {
    if (_rolActual != RolUsuario.administrador) return false;
    // Solo mostrar acciones si el evento está pendiente de validación.
    return _eventoActual.validado == false;
  }

  // Determina si se muestra el FAB de escanear asistencia.
  bool get _mostrarFabEscanear {
    // Solo para organizadores viendo sus propios eventos validados.
    if (_rolActual != RolUsuario.organizador) return false;
    if (widget.origen != OrigenDetalle.misEventos) return false;
    if (!_eventoActual.validado) return false;
    if (_eventoActual.entradaLibre) return false;
    // Solo si el evento no requiere entrada libre (requiere control de asistencia).
    // O siempre mostrar para eventos validados.
    return true;
  }

  // Determina si se muestra el botón de ver calificaciones.
  bool get _mostrarBotonCalificaciones {
    // Para administradores, pueden ver calificaciones de cualquier evento validado.
    if (_rolActual == RolUsuario.administrador) {
      return _eventoActual.validado;
    }
    // Para organizadores, solo sus propios eventos validados.
    if (_rolActual == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos &&
        _eventoActual.validado) {
      return true;
    }
    return false;
  }

  // Determina si se muestra el botón de ver asistentes.
  bool get _mostrarBotonAsistentes {
    // Solo para organizadores viendo sus propios eventos validados.
    if (_rolActual != RolUsuario.organizador) return false;
    if (widget.origen != OrigenDetalle.misEventos) return false;
    if (!_eventoActual.validado) return false;
    return true;
  }

  // Determina si el estudiante puede calificar el evento.
  bool _puedeCalificar(AsistenciaEventoState asistenciaState) {
    // Solo estudiantes pueden calificar.
    if (_rolActual != RolUsuario.estudiante) return false;

    // El evento debe haber pasado.
    if (!_eventoYaPaso) return false;

    // El evento no debe estar cancelado.
    if (_eventoActual.cancelado) return false;

    // Si es entrada libre, puede calificar.
    if (_eventoActual.entradaLibre) return true;

    // Si no es entrada libre, debe tener asistencia marcada (asistio = 1).
    if (asistenciaState is AsistenciaEventoRegistrado) {
      return asistenciaState.asistencia.asistio == 1;
    }

    return false;
  }

  // Abre el escáner de asistencia.
  void _abrirEscanerAsistencia() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EscanerAsistenciaPage(
          idEvento: _eventoActual.id,
          nombreEvento: _eventoActual.nombre,
        ),
      ),
    );
  }

  // Abre la página de calificaciones del evento.
  void _abrirCalificaciones() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CalificacionesEventoPage(
          idEvento: _eventoActual.id,
          nombreEvento: _eventoActual.nombre,
        ),
      ),
    );
  }

  // Abre la página de lista de asistentes.
  void _abrirListaAsistentes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListaAsistentesPage(
          idEvento: _eventoActual.id,
          nombreEvento: _eventoActual.nombre,
          entradaLibre: _eventoActual.entradaLibre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: _mostrarFabEscanear
          ? FloatingActionButton.extended(
              onPressed: _abrirEscanerAsistencia,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pasar Asistencia'),
              backgroundColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              foregroundColor: Colors.white,
            )
          : null,
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

                  // Banner de evento cancelado.
                  if (_eventoActual.cancelado) ...[
                    const BannerEventoCancelado(),
                    const SizedBox(height: 16),
                  ],

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
                      mostrarIdEvento: _rolActual == RolUsuario.administrador,
                    ),
                  ],

                  // Botón de ver calificaciones para organizadores.
                  if (_mostrarBotonCalificaciones) ...[
                    const SizedBox(height: 24),
                    BotonVerCalificaciones(
                      onPressed: _abrirCalificaciones,
                    ),
                  ],

                  // Botón de ver asistentes para organizadores.
                  if (_mostrarBotonAsistentes) ...[
                    const SizedBox(height: 16),
                    BotonVerAsistentes(
                      onPressed: _abrirListaAsistentes,
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

                  // Botón de asistencia para estudiantes.
                  if (_mostrarBotonAsistencia) ...[
                    const SizedBox(height: 24),
                    _construirBotonAsistencia(),
                  ],

                  // Sección de calificación para estudiantes.
                  _construirSeccionCalificacion(),

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
    // Determina si se puede cancelar el evento.
    final puedeCancelar = _rolActual == RolUsuario.organizador &&
        widget.origen == OrigenDetalle.misEventos &&
        _eventoActual.validado &&
        !_eventoActual.cancelado;

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
            onCancelar: _mostrarDialogoCancelar,
            mostrarCancelar: puedeCancelar,
          ),
      ],
    );
  }

  // Construye el botón de asistencia para estudiantes.
  Widget _construirBotonAsistencia() {
    final asistenciaState = ref.watch(asistenciaProvider);
    final perfil = ref.watch(perfilActualProvider);

    // Si ya se le marcó asistencia, no mostrar el botón.
    if (_yaSeLeMarcoAsistencia(asistenciaState)) {
      return const SizedBox.shrink();
    }

    // Determina el estado del botón.
    final estaCargando = asistenciaState is AsistenciaEventoCargando;
    final estaRegistrado = asistenciaState is AsistenciaEventoRegistrado;

    return BotonAsistencia(
      estaRegistrado: estaRegistrado,
      estaCargando: estaCargando,
      onRegistrar: () => _registrarAsistencia(perfil),
      onCancelar: () => _cancelarAsistencia(asistenciaState),
    );
  }

  // Construye la sección de calificación para estudiantes.
  Widget _construirSeccionCalificacion() {
    final asistenciaState = ref.watch(asistenciaProvider);
    final calificacionState = ref.watch(calificacionEstudianteProvider);

    // Verifica si puede calificar.
    if (!_puedeCalificar(asistenciaState)) {
      return const SizedBox.shrink();
    }

    // Si ya calificó, muestra la calificación.
    if (calificacionState is CalificacionEstudianteCalificado) {
      return _construirCalificacionExistente(calificacionState.calificacion);
    }

    // Si no ha calificado, muestra el botón para calificar.
    if (calificacionState is CalificacionEstudianteNoCalificado) {
      return Column(
        children: [
          const SizedBox(height: 24),
          BotonCalificarEvento(onPressed: _mostrarDialogoCalificar),
        ],
      );
    }

    // Si está cargando, muestra un indicador.
    if (calificacionState is CalificacionEstudianteCargando) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return const SizedBox.shrink();
  }

  // Construye el widget que muestra la calificación existente.
  Widget _construirCalificacionExistente(dynamic calificacion) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.amber.withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ya calificaste este evento',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final estrella = index + 1;
                  return Icon(
                    estrella <= calificacion.calificacion
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    size: 28,
                  );
                }),
              ),
              if (calificacion.comentario != null &&
                  calificacion.comentario!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '"${calificacion.comentario}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Muestra el diálogo para calificar el evento.
  void _mostrarDialogoCalificar() {
    DialogoCalificarEvento.mostrar(
      context: context,
      nombreEvento: _eventoActual.nombre,
      onCalificar: (calificacion, comentario) async {
        final perfil = ref.read(perfilActualProvider);
        if (perfil == null) return false;

        final exito = await ref
            .read(calificacionEstudianteProvider.notifier)
            .calificar(
              idPerfil: perfil.idPerfil,
              idEvento: _eventoActual.id,
              calificacion: calificacion,
              comentario: comentario,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                exito
                    ? '¡Gracias por tu calificación!'
                    : 'Error al enviar calificación',
              ),
              backgroundColor: exito ? Colors.green : Colors.red,
            ),
          );
        }

        return exito;
      },
    );
  }

  // Registra la asistencia del estudiante.
  Future<void> _registrarAsistencia(PerfilModel? perfil) async {
    if (perfil == null) return;

    final exito = await ref.read(asistenciaProvider.notifier).registrarAsistencia(
          idPerfil: perfil.idPerfil,
          idEvento: _eventoActual.id,
          entradaLibre: _eventoActual.entradaLibre,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exito
                ? '¡Te has registrado al evento!'
                : 'Error al registrar asistencia',
          ),
          backgroundColor: exito ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Cancela la asistencia del estudiante.
  void _cancelarAsistencia(AsistenciaEventoState estado) {
    if (estado is! AsistenciaEventoRegistrado) return;

    DialogoCancelarAsistencia.mostrar(
      context: context,
      nombreEvento: _eventoActual.nombre,
      onConfirmar: () async {
        final exito = await ref
            .read(asistenciaProvider.notifier)
            .cancelarAsistencia(estado.asistencia.id);

        if (exito && widget.origen == OrigenDetalle.misEventosEstudiante) {
          // Elimina el evento de la lista de eventos del estudiante.
          ref
              .read(eventosEstudianteProvider.notifier)
              .eliminarEvento(_eventoActual.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                exito
                    ? 'Has cancelado tu asistencia'
                    : 'Error al cancelar asistencia',
              ),
              backgroundColor: exito ? Colors.orange : Colors.red,
            ),
          );

          // Si viene de mis eventos estudiante, vuelve atrás.
          if (exito && widget.origen == OrigenDetalle.misEventosEstudiante) {
            Navigator.of(context).pop();
          }
        }
      },
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

  // Muestra el diálogo de confirmación para cancelar evento.
  void _mostrarDialogoCancelar() {
    DialogoCancelarEvento.mostrar(
      context: context,
      nombreEvento: _eventoActual.nombre,
      onConfirmar: _cancelarEvento,
    );
  }

  // Cancela el evento.
  Future<void> _cancelarEvento() async {
    final notifier = ref.read(cancelarEventoProvider.notifier);
    final evento = await notifier.cancelarEvento(_eventoActual.id);

    if (!mounted) return;

    if (evento != null) {
      setState(() {
        _eventoActual = evento;
      });
      widget.onEventoActualizado?.call(evento);

      // Recarga la lista de eventos del organizador.
      ref.read(eventosOrganizadorProvider.notifier).recargarEventos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento cancelado correctamente'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      final state = ref.read(cancelarEventoProvider);
      if (state is CancelarEventoError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: ${state.mensaje}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
