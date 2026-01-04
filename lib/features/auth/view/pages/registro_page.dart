import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_form_field.dart';
import 'package:escomevents_app/features/auth/models/auth_state.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Página de registro de nuevos usuarios.
class RegistroPage extends ConsumerStatefulWidget {
  const RegistroPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends ConsumerState<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  bool _ocultarContrasena = true;
  bool _ocultarConfirmarContrasena = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final exito = await ref.read(authProvider.notifier).registrar(
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          contrasena: _contrasenaController.text,
        );

    if (!mounted) return;

    if (exito) {
      final perfil = ref.read(perfilActualProvider);
      
      if (perfil?.requiereConfirmacion == true) {
        // Muestra un diálogo indicando que debe confirmar su correo.
        _mostrarDialogoConfirmacion();
      } else {
        // Si no requiere confirmación, navega a bienvenida.
        context.go(RutasApp.bienvenida, extra: perfil?.rol);
      }
    }
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Registro exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hemos enviado un correo de confirmación a:',
            ),
            const SizedBox(height: 8),
            Text(
              _correoController.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
            ),
            const SizedBox(height: 8),
            Text(
              'Si no lo encuentras, revisa tu carpeta de spam.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RutasApp.login);
            },
            child: const Text('Ir a iniciar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final estaCargando = authState is AuthCargando;

    // Escucha cambios de estado para mostrar errores.
    ref.listen<AuthState>(authProvider, (anterior, nuevo) {
      if (nuevo is AuthError) {
        // Cierra cualquier SnackBar anterior.
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevo.mensaje),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        // Limpia el error para evitar que se muestre de nuevo.
        ref.read(authProvider.notifier).limpiarError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título.
                  Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa tus datos para registrarte',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de nombre.
                  CustomInputField(
                    label: 'Nombre completo',
                    hintText: 'Tu nombre',
                    prefixIcon: Icons.person_outlined,
                    controller: _nombreController,
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de correo.
                  CustomInputField(
                    label: 'Correo electrónico',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icons.email_outlined,
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!valor.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña.
                  CustomInputField(
                    label: 'Contraseña',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _ocultarContrasena,
                    controller: _contrasenaController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarContrasena
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _ocultarContrasena = !_ocultarContrasena);
                      },
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (valor.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de confirmar contraseña.
                  CustomInputField(
                    label: 'Confirmar contraseña',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _ocultarConfirmarContrasena,
                    controller: _confirmarContrasenaController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmarContrasena
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() =>
                            _ocultarConfirmarContrasena = !_ocultarConfirmarContrasena);
                      },
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor confirma tu contraseña';
                      }
                      if (valor != _contrasenaController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de registro.
                  CustomButton(
                    texto: 'Registrarse',
                    onPressed: estaCargando ? null : _registrar,
                    cargando: estaCargando,
                    iconoInicio: Icons.person_add,
                  ),
                  const SizedBox(height: 16),

                  // Enlace a login.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
