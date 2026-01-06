import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_form_field.dart';
import 'package:escomevents_app/features/auth/models/auth_state.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Página de inicio de sesión.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final exito = await ref.read(authProvider.notifier).iniciarSesion(
          correo: _correoController.text.trim(),
          contrasena: _contrasenaController.text,
        );

    if (!mounted) return;

    if (exito) {
      context.go(RutasApp.inicio);
    }
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
                  // Logo o título.
                  Icon(
                    Icons.event,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EscomEvents',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 40),

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
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (valor.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Enlace de olvidé contraseña.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implementar recuperación de contraseña.
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de iniciar sesión.
                  CustomButton(
                    texto: 'Iniciar sesión',
                    onPressed: estaCargando ? null : _iniciarSesion,
                    cargando: estaCargando,
                    iconoInicio: Icons.login,
                  ),
                  const SizedBox(height: 16),

                  // Enlace a registro.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(RutasApp.registro);
                        },
                        child: Text(
                          'Regístrate',
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
