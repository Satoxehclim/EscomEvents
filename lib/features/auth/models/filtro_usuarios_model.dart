import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';

// Filtro para la lista de usuarios.
class FiltroUsuarios {
  // Rol por el cual filtrar (null = todos).
  final RolUsuario? rol;

  const FiltroUsuarios({
    this.rol,
  });

  // Crea una copia con los valores especificados.
  FiltroUsuarios copyWith({
    RolUsuario? rol,
    bool limpiarRol = false,
  }) {
    return FiltroUsuarios(
      rol: limpiarRol ? null : (rol ?? this.rol),
    );
  }

  // Indica si hay algún filtro activo.
  bool get tieneFiltrActivo => rol != null;
}
