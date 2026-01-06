import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/formulario_editar_evento.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Origen desde donde se navega al detalle del evento.
enum OrigenDetalle {
  misEventos,
  eventos,
}

// Página que muestra los detalles completos de un evento.
class DetalleEventoPage extends StatefulWidget {
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
  State<DetalleEventoPage> createState() => _DetalleEventoPageState();
}

class _DetalleEventoPageState extends State<DetalleEventoPage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen.
          _construirAppBar(context, isDark),

          // Contenido.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del evento y menú de opciones.
                  Row(
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
                        _construirMenuOpciones(context, theme, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categorías.
                  if (_eventoActual.categorias.isNotEmpty)
                    _construirCategorias(isDark),

                  // Información del organizador.
                  if (widget.nombreOrganizador != null) ...[
                    const SizedBox(height: 20),
                    _construirInfoOrganizador(theme, isDark),
                  ],

                  // Detalles principales.
                  const SizedBox(height: 20),
                  _construirDetallesPrincipales(theme, isDark),

                  // Descripción.
                  if (_eventoActual.descripcion != null &&
                      _eventoActual.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _construirSeccion(
                      theme: theme,
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
                  if (_mostrarResumenComentarios &&
                      _eventoActual.resumenComentarios != null &&
                      _eventoActual.resumenComentarios!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _construirSeccion(
                      theme: theme,
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
                    _construirSeccion(
                      theme: theme,
                      titulo: 'Flyer del evento',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _eventoActual.flyer!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Información administrativa (solo para roles permitidos).
                  if (_mostrarInfoAdministrativa) ...[
                    const SizedBox(height: 24),
                    _construirInfoAdministrativa(theme, isDark),
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

  // Construye el menú de opciones (Editar, Eliminar).
  Widget _construirMenuOpciones(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSelected: (opcion) {
        switch (opcion) {
          case 'editar':
            _abrirFormularioEdicion(context);
            break;
          case 'eliminar':
            _mostrarDialogoEliminar(context, isDark);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(
                Icons.edit,
                size: 20,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              const Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: 20,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 12),
              Text(
                'Eliminar',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Abre el formulario de edición del evento.
  void _abrirFormularioEdicion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormularioEditarEvento(
          evento: _eventoActual,
          onGuardar: (eventoActualizado) {
            // Actualiza el estado local para reflejar los cambios.
            setState(() {
              _eventoActual = eventoActualizado;
            });
            // Notifica al padre para que actualice la lista.
            widget.onEventoActualizado?.call(eventoActualizado);
            Navigator.of(context).pop(); // Cierra el formulario.
          },
          onCancelar: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Muestra el diálogo de confirmación para eliminar.
  void _mostrarDialogoEliminar(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Eliminar evento'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_eventoActual.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onEventoEliminado?.call();
              Navigator.of(context).pop(); // Cierra la página de detalle.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Construye el AppBar con la imagen del evento.
  Widget _construirAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
              .withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          color: isDark ? AppColors.darkPrimary: AppColors.lightPrimary,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo.
            if (_eventoActual.imageUrl != null &&
                _eventoActual.imageUrl!.isNotEmpty)
              Image.network(
                _eventoActual.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  child: Icon(
                    _eventoActual.categorias.isNotEmpty
                        ? _eventoActual.categorias.first.icono ?? Icons.event
                        : Icons.event,
                    size: 80,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
              )
            else
              Container(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                child: Center(
                  child: Icon(
                    _eventoActual.categorias.isNotEmpty
                        ? _eventoActual.categorias.first.icono ?? Icons.event
                        : Icons.event,
                    size: 80,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
              ),

            // Gradiente oscuro en la parte inferior.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Badge de fecha.
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground)
                      .withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_eventoActual.fecha.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    Text(
                      _obtenerNombreMes(_eventoActual.fecha.month),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_eventoActual.fecha.year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye los chips de categorías.
  Widget _construirCategorias(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _eventoActual.categorias.map((categoria) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimary.withOpacity(0.2)
                : AppColors.lightPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoria.icono != null)
                Icon(
                  categoria.icono,
                  size: 16,
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              if (categoria.icono != null) const SizedBox(width: 4),
              Text(
                categoria.nombre,
                style: TextStyle(
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Construye la información del organizador.
  Widget _construirInfoOrganizador(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkPrimary.withOpacity(0.1)
            : AppColors.lightPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkPrimary.withOpacity(0.3)
              : AppColors.lightPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organizado por',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.nombreOrganizador!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye los detalles principales del evento.
  Widget _construirDetallesPrincipales(ThemeData theme, bool isDark) {
    final formatoHora = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Fecha y hora.
          _construirFilaDetalle(
            icono: Icons.calendar_today,
            titulo: 'Fecha y hora',
            valor:
                '${_formatearFecha(_eventoActual.fecha)} a las ${formatoHora.format(_eventoActual.fecha)} hrs',
            isDark: isDark,
          ),

          const Divider(height: 24),

          // Lugar.
          _construirFilaDetalle(
            icono: Icons.location_on,
            titulo: 'Lugar',
            valor: _eventoActual.lugar,
            isDark: isDark,
          ),

          const Divider(height: 24),

          // Entrada.
          _construirFilaDetalle(
            icono: _eventoActual.entradaLibre ? Icons.check_circle : Icons.lock,
            titulo: 'Entrada',
            valor: _eventoActual.entradaLibre
                ? 'Libre'
                : 'Se requiere pasar asistencia',
            isDark: isDark,
          ),

          // Fecha de publicación.
          if (_mostrarFechaPublicado &&
              _eventoActual.fechaPublicado != null) ...[
            const Divider(height: 24),
            _construirFilaDetalle(
              icono: Icons.publish,
              titulo: 'Publicado',
              valor: _formatearFecha(_eventoActual.fechaPublicado!),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // Construye una fila de detalle.
  Widget _construirFilaDetalle({
    required IconData icono,
    required String titulo,
    required String valor,
    required bool isDark,
    Color? valorColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimary.withOpacity(0.2)
                : AppColors.lightPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icono,
            size: 20,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construye una sección con título.
  Widget _construirSeccion({
    required ThemeData theme,
    required String titulo,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // Construye la información administrativa.
  Widget _construirInfoAdministrativa(ThemeData theme, bool isDark) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withOpacity(0.1)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información administrativa',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado de validación.
          if (_mostrarValidado)
            _construirFilaAdmin(
              titulo: 'Estado',
              valor: _eventoActual.validado ? 'Aprobado' : 'Pendiente',
              valorColor:
                  _eventoActual.validado ? Colors.green : Colors.orange,
              icono:
                  _eventoActual.validado ? Icons.check_circle : Icons.pending,
            ),

          // Fecha de creación.
          if (_mostrarCreatedAt) ...[
            const SizedBox(height: 12),
            _construirFilaAdmin(
              titulo: 'Creado',
              valor: formatoFecha.format(_eventoActual.fechaCreacion),
              icono: Icons.access_time,
            ),
          ],

          // ID del evento (solo admin).
          if (widget.rol == RolUsuario.administrador) ...[
            const SizedBox(height: 12),
            _construirFilaAdmin(
              titulo: 'ID Evento',
              valor: '${_eventoActual.id}',
              icono: Icons.tag,
            ),
          ],
        ],
      ),
    );
  }

  // Construye una fila de información administrativa.
  Widget _construirFilaAdmin({
    required String titulo,
    required String valor,
    required IconData icono,
    Color? valorColor,
  }) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$titulo: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: valorColor,
          ),
        ),
      ],
    );
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

  // Determina si se muestra la fecha de publicación.
  bool get _mostrarFechaPublicado => true;

  // Determina si se muestra el resumen de comentarios.
  bool get _mostrarResumenComentarios => true;

  // Determina si se muestra la información administrativa.
  bool get _mostrarInfoAdministrativa => _mostrarValidado || _mostrarCreatedAt;

  // Formatea una fecha en español.
  String _formatearFecha(DateTime fecha) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];

    return '$diaSemana ${fecha.day} de $mes de ${fecha.year}';
  }

  // Obtiene el nombre corto del mes.
  String _obtenerNombreMes(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];
    return months[month - 1];
  }
}
