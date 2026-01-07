import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Roles de usuario disponibles en la aplicación.
enum RolUsuario { estudiante, organizador, administrador }

// Página principal de bienvenida con navegación inferior.
//
// La navegación y contenido puede variar según el [rol] del usuario.
class BienvenidaPage extends StatefulWidget {
  // Rol del usuario actual. Por defecto es [RolUsuario.estudiante].
  final RolUsuario rol;

  // Widget hijo que se muestra en el cuerpo del Scaffold.
  final Widget child;

  const BienvenidaPage({
    super.key,
    this.rol = RolUsuario.estudiante,
    required this.child,
  });

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  // Obtiene las rutas disponibles según el rol del usuario.
  List<String> _obtenerRutas() {
    final rutasBase = <String>[
      RutasApp.inicio,
      RutasApp.eventos,
    ];

    // Agrega rutas adicionales según el rol.
    switch (widget.rol) {
      case RolUsuario.organizador:
        rutasBase.add(RutasApp.misEventos);
        break;
      case RolUsuario.administrador:
        rutasBase.add(RutasApp.adminEventos);
        break;
      case RolUsuario.estudiante:
        // Los estudiantes solo tienen las rutas base.
        break;
    }

    return rutasBase;
  }

  // Obtiene el índice actual basado en la ruta.
  int _obtenerIndiceActual(String ubicacion) {
    final rutas = _obtenerRutas();
    final indice = rutas.indexWhere((ruta) => ubicacion.startsWith(ruta));
    return indice >= 0 ? indice : 0;
  }

  // Navega a la ruta correspondiente al índice.
  void _navegarA(int indice) {
    final rutas = _obtenerRutas();
    if (indice >= 0 && indice < rutas.length) {
      context.go(rutas[indice]);
    }
  }

  // Obtiene los items de navegación según el rol del usuario.
  List<BottomNavigationBarItem> _obtenerItemsNavegacion() {
    // Items base para todos los roles.
    final itemsBase = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_outlined),
        activeIcon: Icon(Icons.event),
        label: 'Eventos',
      ),
    ];

    // Agrega items adicionales según el rol.
    switch (widget.rol) {
      case RolUsuario.organizador:
        itemsBase.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Mis Eventos',
          ),
        );
        break;
      case RolUsuario.administrador:
        itemsBase.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Administrar',
          ),
        );
        break;
      case RolUsuario.estudiante:
        // Los estudiantes solo tienen los items base.
        break;
    }

    return itemsBase;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemsNavegacion = _obtenerItemsNavegacion();
    final ubicacionActual = GoRouterState.of(context).uri.path;
    final indiceActual = _obtenerIndiceActual(ubicacionActual);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: indiceActual,
          onTap: _navegarA,
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightBackground,
          selectedItemColor:
              isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: itemsNavegacion,
        ),
      ),
    );
  }
}
