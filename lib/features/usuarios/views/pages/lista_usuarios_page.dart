import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/features/usuarios/models/filtro_usuarios_model.dart';
import 'package:escomevents_app/features/home/models/perfil_model.dart';
import 'package:escomevents_app/features/home/views/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/usuarios/viewmodel/usuario_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Página para ver y gestionar la lista de usuarios registrados.
class ListaUsuariosPage extends ConsumerStatefulWidget {
  const ListaUsuariosPage({super.key});

  @override
  ConsumerState<ListaUsuariosPage> createState() => _ListaUsuariosPageState();
}

class _ListaUsuariosPageState extends ConsumerState<ListaUsuariosPage> {
  final ScrollController _scrollController = ScrollController();
  FiltroUsuarios _filtro = const FiltroUsuarios();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarios();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(listaUsuariosProvider.notifier).cargarMasUsuarios();
    }
  }

  Future<void> _cargarUsuarios() async {
    await ref.read(listaUsuariosProvider.notifier).cargarUsuarios(
          filtro: _filtro,
        );
  }

  void _aplicarFiltro(RolUsuario? rol) {
    setState(() {
      _filtro = FiltroUsuarios(rol: rol);
    });
    _cargarUsuarios();
  }

  Future<void> _confirmarEliminacion(PerfilModel usuario) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Eliminar usuario'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${usuario.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          CustomButton(
            onPressed: () => Navigator.of(context).pop(false),
            texto: 'Cancelar',
            tipo: CustomButtonType.outlined,
            anchoCompleto: false,
          ),
          CustomButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            texto: 'Eliminar',
            tipo: CustomButtonType.danger,
            anchoCompleto: false,
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _eliminarUsuario(usuario);
    }
  }

  Future<void> _eliminarUsuario(PerfilModel usuario) async {
    final exito = await ref
        .read(listaUsuariosProvider.notifier)
        .eliminarUsuario(usuario.idPerfil);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'Usuario eliminado exitosamente'
              : 'Error al eliminar el usuario',
        ),
        backgroundColor: exito ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final estado = ref.watch(listaUsuariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usuarios',
          style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros y contador.
            _construirSeccionFiltros(theme, isDark, estado),
            
            // Lista de usuarios.
            Expanded(
              child: _construirContenido(estado, theme, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(RutasApp.registrarUsuario);
          // Recarga la lista al regresar de registrar usuario.
          _cargarUsuarios();
        },
        backgroundColor:
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _construirSeccionFiltros(
    ThemeData theme,
    bool isDark,
    ListaUsuariosState estado,
  ) {
    final totalUsuarios = estado is ListaUsuariosCargado
        ? estado.totalUsuarios
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contador de usuarios.
          Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                '$totalUsuarios usuario${totalUsuarios != 1 ? 's' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_filtro.rol != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _obtenerColorRol(_filtro.rol!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _obtenerNombreRol(_filtro.rol!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _obtenerColorRol(_filtro.rol!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Chips de filtro.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _construirChipFiltro(
                  label: 'Todos',
                  seleccionado: _filtro.rol == null,
                  onTap: () => _aplicarFiltro(null),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _construirChipFiltro(
                  label: 'Estudiantes',
                  seleccionado: _filtro.rol == RolUsuario.estudiante,
                  onTap: () => _aplicarFiltro(RolUsuario.estudiante),
                  isDark: isDark,
                  color: _obtenerColorRol(RolUsuario.estudiante),
                ),
                const SizedBox(width: 8),
                _construirChipFiltro(
                  label: 'Organizadores',
                  seleccionado: _filtro.rol == RolUsuario.organizador,
                  onTap: () => _aplicarFiltro(RolUsuario.organizador),
                  isDark: isDark,
                  color: _obtenerColorRol(RolUsuario.organizador),
                ),
                const SizedBox(width: 8),
                _construirChipFiltro(
                  label: 'Administradores',
                  seleccionado: _filtro.rol == RolUsuario.administrador,
                  onTap: () => _aplicarFiltro(RolUsuario.administrador),
                  isDark: isDark,
                  color: _obtenerColorRol(RolUsuario.administrador),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipFiltro({
    required String label,
    required bool seleccionado,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final colorPrimario = color ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return FilterChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => onTap(),
      selectedColor: colorPrimario,
      checkmarkColor: seleccionado ? Colors.white
                      : (isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary),
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white
                      : (isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary),
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: seleccionado ? colorPrimario : (isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary),
      ),
    );
  }

  Widget _construirContenido(
    ListaUsuariosState estado,
    ThemeData theme,
    bool isDark,
  ) {
    return switch (estado) {
      ListaUsuariosInicial() => _construirEstadoCargando(isDark),
      ListaUsuariosCargando() => _construirEstadoCargando(isDark),
      ListaUsuariosError(mensaje: final mensaje) =>
        _construirEstadoError(mensaje, theme, isDark),
      ListaUsuariosCargado(
        usuarios: final usuarios,
        hayMas: final hayMas,
        cargandoMas: final cargandoMas
      ) =>
        usuarios.isEmpty
            ? _construirEstadoVacio(theme, isDark)
            : _construirListaUsuarios(
                usuarios,
                theme,
                isDark,
                hayMas: hayMas,
                cargandoMas: cargandoMas,
              ),
    };
  }

  Widget _construirEstadoCargando(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
    );
  }

  Widget _construirEstadoError(
    String mensaje,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarUsuarios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEstadoVacio(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (_filtro.rol != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _aplicarFiltro(null),
              child: const Text('Mostrar todos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirListaUsuarios(
    List<PerfilModel> usuarios,
    ThemeData theme,
    bool isDark, {
    bool hayMas = false,
    bool cargandoMas = false,
  }) {
    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: usuarios.length + (cargandoMas ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == usuarios.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
            );
          }

          final usuario = usuarios[index];
          return _construirTarjetaUsuario(usuario, theme, isDark);
        },
      ),
    );
  }

  Widget _construirTarjetaUsuario(
    PerfilModel usuario,
    ThemeData theme,
    bool isDark,
  ) {
    final colorRol = _obtenerColorRol(usuario.rol);
    final tieneAvatar = usuario.avatar != null && usuario.avatar!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar del usuario.
            CircleAvatar(
              radius: 28,
              backgroundColor: colorRol.withOpacity(0.2),
              backgroundImage: tieneAvatar
                  ? NetworkImage(usuario.avatar!)
                  : null,
              child: !tieneAvatar
                  ? Text(
                      usuario.nombre.isNotEmpty
                          ? usuario.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorRol,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Información del usuario.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorRol.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _obtenerIconoRol(usuario.rol),
                          size: 14,
                          color: colorRol,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _obtenerNombreRol(usuario.rol),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorRol,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botón de eliminar.
            IconButton(
              onPressed: () => _confirmarEliminacion(usuario),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              tooltip: 'Eliminar usuario',
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerNombreRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.estudiante:
        return 'Estudiante';
      case RolUsuario.organizador:
        return 'Organizador';
      case RolUsuario.administrador:
        return 'Administrador';
    }
  }

  IconData _obtenerIconoRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.estudiante:
        return Icons.school;
      case RolUsuario.organizador:
        return Icons.event_note;
      case RolUsuario.administrador:
        return Icons.admin_panel_settings;
    }
  }

  Color _obtenerColorRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.estudiante:
        return const Color(0xFF3B82F6); // Azul.
      case RolUsuario.organizador:
        return const Color(0xFFF59E0B); // Naranja.
      case RolUsuario.administrador:
        return const Color(0xFF10B981); // Verde.
    }
  }
}
