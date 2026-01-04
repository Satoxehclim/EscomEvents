import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/features/auth/view/pages/home_page.dart';
import 'package:escomevents_app/features/eventos/views/pages/eventos.dart';
import 'package:flutter/material.dart';

/// Roles de usuario disponibles en la aplicación.
enum RolUsuario { estudiante, organizador, administrador }

/// Página principal de bienvenida con navegación inferior.
///
/// La navegación y contenido puede variar según el [rol] del usuario.
class BienvenidaPage extends StatefulWidget {
  /// Rol del usuario actual. Por defecto es [RolUsuario.estudiante].
  final RolUsuario rol;

  const BienvenidaPage({
    Key? key,
    this.rol = RolUsuario.estudiante,
  }) : super(key: key);

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  int _indiceActual = 0;

  /// Obtiene las páginas disponibles según el rol del usuario.
  List<Widget> _obtenerPaginas() {
    // Páginas base para todos los roles.
    final paginasBase = <Widget>[
      const HomePage(),
      const EventsScreen(),
    ];

    // Agrega páginas adicionales según el rol.
    switch (widget.rol) {
      case RolUsuario.organizador:
        // TODO: Agregar páginas específicas para organizadores.
        // Ejemplo: paginasBase.add(const MisEventosPage());
        break;
      case RolUsuario.administrador:
        // TODO: Agregar páginas específicas para administradors.
        // Ejemplo: paginasBase.add(const ValidarEventosPage());
        break;
      case RolUsuario.estudiante:
        // Los estudiantes solo tienen las páginas base.
        break;
    }

    return paginasBase;
  }

  /// Obtiene los items de navegación según el rol del usuario.
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
        // TODO: Agregar items específicos para organizadores.
        // Ejemplo:
        // itemsBase.add(const BottomNavigationBarItem(
        //   icon: Icon(Icons.add_circle_outline),
        //   activeIcon: Icon(Icons.add_circle),
        //   label: 'Mis Eventos',
        // ));
        break;
      case RolUsuario.administrador:
        // TODO: Agregar items específicos para administradors.
        // Ejemplo:
        // itemsBase.add(const BottomNavigationBarItem(
        //   icon: Icon(Icons.verified_outlined),
        //   activeIcon: Icon(Icons.verified),
        //   label: 'Validar',
        // ));
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
    final paginas = _obtenerPaginas();
    final itemsNavegacion = _obtenerItemsNavegacion();

    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: paginas,
      ),
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
          currentIndex: _indiceActual,
          onTap: (indice) => setState(() => _indiceActual = indice),
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
