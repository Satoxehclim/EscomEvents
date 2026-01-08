import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_form_field.dart';
import 'package:escomevents_app/features/auth/view/pages/bienvenida_page.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Página para que los administradores registren nuevos usuarios.
class RegistrarUsuarioPage extends ConsumerStatefulWidget {
  const RegistrarUsuarioPage({super.key});

  @override
  ConsumerState<RegistrarUsuarioPage> createState() =>
      _RegistrarUsuarioPageState();
}

class _RegistrarUsuarioPageState extends ConsumerState<RegistrarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _confirmarCorreoController = TextEditingController();
  RolUsuario _rolSeleccionado = RolUsuario.estudiante;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _confirmarCorreoController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final exito = await ref.read(invitarUsuarioProvider.notifier).invitarUsuario(
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          rol: _rolSeleccionado,
        );

    if (!mounted) return;

    if (exito) {
      _mostrarDialogoExito();
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('¡Usuario creado!'),
          ],
        ),
        content: Text(
          'Se ha creado la cuenta para ${_correoController.text.trim()}.\n\n'
          'El usuario recibirá un correo para establecer su contraseña antes de poder iniciar sesión.',
        ),
        actions: [
          CustomButton(
            texto: 'Aceptar',
            onPressed: () {
              Navigator.of(context).pop();
              _limpiarFormulario();
            },
            anchoCompleto: false,
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _correoController.clear();
    _confirmarCorreoController.clear();
    setState(() {
      _rolSeleccionado = RolUsuario.estudiante;
    });
    ref.read(invitarUsuarioProvider.notifier).reiniciar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invitarState = ref.watch(invitarUsuarioProvider);
    final estaCargando = invitarState is InvitarUsuarioCargando;

    // Escucha cambios de estado para mostrar errores.
    ref.listen<InvitarUsuarioState>(invitarUsuarioProvider, (anterior, nuevo) {
      if (nuevo is InvitarUsuarioError) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevo.mensaje),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar Usuario',
          style: TextStyle(
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono y descripción.
                _construirEncabezado(theme, isDark),
                const SizedBox(height: 32),

                // Campo de nombre.
                CustomInputField(
                  label: 'Nombre completo',
                  hintText: 'Nombre del usuario',
                  prefixIcon: Icons.person_outlined,
                  controller: _nombreController,
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Por favor ingresa el nombre';
                    }
                    if (valor.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de rol.
                _construirSelectorRol(theme, isDark),
                const SizedBox(height: 16),

                // Campo de correo.
                CustomInputField(
                  label: 'Correo electrónico',
                  hintText: 'correo@ejemplo.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Por favor ingresa el correo';
                    }
                    if (!valor.contains('@') || !valor.contains('.')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de confirmar correo.
                CustomInputField(
                  label: 'Confirmar correo electrónico',
                  hintText: 'Repite el correo',
                  prefixIcon: Icons.email_outlined,
                  controller: _confirmarCorreoController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Por favor confirma el correo';
                    }
                    if (valor != _correoController.text) {
                      return 'Los correos no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón de registrar.
                CustomButton(
                  texto: 'Enviar invitación',
                  onPressed: estaCargando ? null : _registrarUsuario,
                  cargando: estaCargando,
                  iconoInicio: Icons.send,
                ),
                const SizedBox(height: 16),

                // Nota informativa.
                _construirNotaInformativa(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirEncabezado(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimary.withOpacity(0.1)
                : AppColors.lightPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_add,
            size: 48,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Registrar nuevo usuario',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El usuario recibirá un correo para establecer su contraseña y activar su cuenta.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _construirSelectorRol(ThemeData theme, bool isDark) {
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol del usuario',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _construirOpcionRol(
                rol: RolUsuario.estudiante,
                titulo: 'Estudiante',
                descripcion: 'Puede ver eventos y registrar asistencia',
                icono: Icons.school_outlined,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
              _construirOpcionRol(
                rol: RolUsuario.organizador,
                titulo: 'Organizador',
                descripcion: 'Puede crear y gestionar eventos',
                icono: Icons.event_note_outlined,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
              _construirOpcionRol(
                rol: RolUsuario.administrador,
                titulo: 'Administrador',
                descripcion: 'Acceso completo al sistema',
                icono: Icons.admin_panel_settings_outlined,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirOpcionRol({
    required RolUsuario rol,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color primaryColor,
    required bool isDark,
  }) {
    final esSeleccionado = _rolSeleccionado == rol;

    return InkWell(
      onTap: () => setState(() => _rolSeleccionado = rol),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esSeleccionado
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: esSeleccionado
                    ? primaryColor.withOpacity(0.2)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icono,
                color: esSeleccionado ? primaryColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esSeleccionado ? primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Radio<RolUsuario>(
              value: rol,
              groupValue: _rolSeleccionado,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _rolSeleccionado = value);
                }
              },
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirNotaInformativa(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Se creará la cuenta y el usuario recibirá un correo para establecer su contraseña.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
