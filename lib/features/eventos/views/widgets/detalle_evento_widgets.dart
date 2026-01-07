import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_text_field.dart';
import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// AppBar expandible con imagen del evento.
class DetalleEventoAppBar extends StatelessWidget {
  final EventModel evento;
  final VoidCallback onBack;

  const DetalleEventoAppBar({
    required this.evento,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _construirImagenFondo(isDark),
            _construirGradiente(),
            _construirBadgeFecha(isDark),
          ],
        ),
      ),
    );
  }

  Widget _construirImagenFondo(bool isDark) {
    final tieneImagen = evento.imageUrl != null && evento.imageUrl!.isNotEmpty;
    final icono = evento.categorias.isNotEmpty
        ? evento.categorias.first.icono ?? Icons.event
        : Icons.event;

    if (tieneImagen) {
      return Image.network(
        evento.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _construirPlaceholder(
          isDark,
          icono,
        ),
      );
    }
    return _construirPlaceholder(isDark, icono);
  }

  Widget _construirPlaceholder(bool isDark, IconData icono) {
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      child: Center(
        child: Icon(
          icono,
          size: 80,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
    );
  }

  Widget _construirGradiente() {
    return Positioned(
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
    );
  }

  Widget _construirBadgeFecha(bool isDark) {
    const meses = [
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

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              '${evento.fecha.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color:
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            Text(
              meses[evento.fecha.month - 1],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${evento.fecha.year}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chips de categorías del evento.
class ChipsCategorias extends StatelessWidget {
  final List<CategoriaModel> categorias;

  const ChipsCategorias({required this.categorias, super.key});

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categorias.map((categoria) {
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
              if (categoria.icono != null) ...[
                Icon(
                  categoria.icono!,
                  size: 16,
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 4),
              ],
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
}

// Información del organizador.
class InfoOrganizador extends StatelessWidget {
  final String nombreOrganizador;

  const InfoOrganizador({required this.nombreOrganizador, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  nombreOrganizador,
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
}

// Detalles principales del evento (fecha, lugar, entrada).
class DetallesPrincipales extends StatelessWidget {
  final EventModel evento;
  final bool mostrarFechaPublicado;

  const DetallesPrincipales({
    required this.evento,
    this.mostrarFechaPublicado = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatoHora = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _FilaDetalle(
            icono: Icons.calendar_today,
            titulo: 'Fecha y hora',
            valor:
                '${_formatearFecha(evento.fecha)} a las ${formatoHora.format(evento.fecha)} hrs',
          ),
          const Divider(height: 24),
          _FilaDetalle(
            icono: Icons.location_on,
            titulo: 'Lugar',
            valor: evento.lugar,
          ),
          const Divider(height: 24),
          _FilaDetalle(
            icono: evento.entradaLibre ? Icons.check_circle : Icons.lock,
            titulo: 'Entrada',
            valor: evento.entradaLibre
                ? 'Libre'
                : 'Se requiere pasar asistencia',
          ),
          if (mostrarFechaPublicado && evento.fechaPublicado != null) ...[
            const Divider(height: 24),
            _FilaDetalle(
              icono: Icons.publish,
              titulo: 'Publicado',
              valor: _formatearFecha(evento.fechaPublicado!),
            ),
          ],
        ],
      ),
    );
  }

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
}

// Fila de detalle individual.
class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color? valorColor;

  const _FilaDetalle({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
}

// Sección con título.
class SeccionConTitulo extends StatelessWidget {
  final String titulo;
  final Widget child;

  const SeccionConTitulo({
    required this.titulo,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}

// Información administrativa del evento.
class InfoAdministrativa extends StatelessWidget {
  final EventModel evento;
  final bool mostrarValidado;
  final bool mostrarCreatedAt;
  final bool mostrarIdEvento;

  const InfoAdministrativa({
    required this.evento,
    this.mostrarValidado = true,
    this.mostrarCreatedAt = true,
    this.mostrarIdEvento = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
          if (mostrarValidado)
            _FilaAdmin(
              titulo: 'Estado',
              valor: evento.validado ? 'Aprobado' : 'Pendiente',
              valorColor: evento.validado ? Colors.green : Colors.orange,
              icono: evento.validado ? Icons.check_circle : Icons.pending,
            ),
          if (mostrarCreatedAt) ...[
            const SizedBox(height: 12),
            _FilaAdmin(
              titulo: 'Creado',
              valor: formatoFecha.format(evento.fechaCreacion),
              icono: Icons.access_time,
            ),
          ],
          if (mostrarIdEvento) ...[
            const SizedBox(height: 12),
            _FilaAdmin(
              titulo: 'ID Evento',
              valor: '${evento.id}',
              icono: Icons.tag,
            ),
          ],
        ],
      ),
    );
  }
}

// Fila de información administrativa.
class _FilaAdmin extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? valorColor;

  const _FilaAdmin({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
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
}

// Comentario del administrador (motivo de rechazo).
class ComentarioAdmin extends StatelessWidget {
  final String comentario;

  const ComentarioAdmin({required this.comentario, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300, width: 1.5),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Motivo de rechazo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comentario,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Acciones de administrador (aprobar/rechazar).
class AccionesAdmin extends StatelessWidget {
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const AccionesAdmin({
    required this.onAprobar,
    required this.onRechazar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Acciones de administrador',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    texto: 'Rechazar',
                    tipo: CustomButtonType.dangerOutlined,
                    iconoInicio: Icons.close,
                    onPressed: onRechazar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    texto: 'Aprobar',
                    tipo: CustomButtonType.success,
                    iconoInicio: Icons.check,
                    onPressed: onAprobar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Menú de opciones (editar/eliminar).
class MenuOpcionesEvento extends StatelessWidget {
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const MenuOpcionesEvento({
    required this.onEditar,
    required this.onEliminar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            onEditar();
            break;
          case 'eliminar':
            onEliminar();
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
}

// Diálogo de confirmación para eliminar evento.
class DialogoEliminarEvento {
  static void mostrar({
    required BuildContext context,
    required String nombreEvento,
    required VoidCallback onConfirmar,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          '¿Estás seguro de que deseas eliminar "$nombreEvento"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          CustomButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            texto: 'Cancelar',
            tipo: CustomButtonType.outlined,
            anchoCompleto: false,
          ),
          CustomButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirmar();
            },
            texto: 'Eliminar',
            tipo: CustomButtonType.danger,
            anchoCompleto: false,
          ),
        ],
      ),
    );
  }
}

// Diálogo para rechazar evento.
class DialogoRechazarEvento {
  static void mostrar({
    required BuildContext context,
    required void Function(String comentario) onRechazar,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comentarioController = TextEditingController();
    String? mensajeError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Rechazar evento'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Estás seguro de que deseas rechazar este evento?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Por favor, indica el motivo del rechazo:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Escribe el motivo del rechazo...',
                  controller: comentarioController,
                  maxLines: 3,
                ),
                if (mensajeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    mensajeError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            IntrinsicWidth(
              child: CustomButton(
                texto: 'Cancelar',
                tipo: CustomButtonType.outlined,
                anchoCompleto: false,
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: CustomButton(
                texto: 'Rechazar',
                tipo: CustomButtonType.danger,
                iconoInicio: Icons.close,
                anchoCompleto: false,
                onPressed: () {
                  if (comentarioController.text.trim().isEmpty) {
                    setDialogState(() {
                      mensajeError = 'Debes indicar el motivo del rechazo';
                    });
                    return;
                  }
                  Navigator.pop(dialogContext);
                  onRechazar(comentarioController.text.trim());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar el flyer del evento.
class FlyerEvento extends StatelessWidget {
  final String flyerUrl;

  const FlyerEvento({required this.flyerUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        flyerUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }
}
