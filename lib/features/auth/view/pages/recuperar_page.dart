import 'package:escomevents_app/core/utils/router.dart';
import 'package:escomevents_app/core/view/widgets/custom_button.dart';
import 'package:escomevents_app/core/view/widgets/custom_form_field.dart';
import 'package:escomevents_app/features/auth/models/auth_state.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecuperarPage extends ConsumerStatefulWidget {
  const RecuperarPage({super.key});

  @override
  ConsumerState<RecuperarPage> createState() => _RecuperarPageState();
}

class _RecuperarPageState extends ConsumerState<RecuperarPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  bool _ocultarContrasena = true;
  bool _ocultarConfirmarContrasena = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _recuperacionContrasena() async {
    if (_correoController.text.trim().isEmpty ||
        !_correoController.text.contains('@') ||
        !_correoController.text.endsWith('alumno.ipn.mx')) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Por favor ingresa un correo institucional válido para recuperar tu contraseña.',
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final bool exito = await ref
        .read(authProvider.notifier)
        .recuperarContrasena(correo: _correoController.text.trim(), contrasena: _contrasenaController.text.trim());

    if (!mounted) return;

    final theme = Theme.of(context);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Se ha enviado un correo confirmando el cambio de contraseña.',
          ),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error al cambiar la contraseña. Verifica los datos e intenta nuevamente.',
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final bool estaCargando = authState is AuthCargando;

    ref.listen<AuthState>(authProvider, (anterior, nuevo) {
      if (nuevo is AuthError) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevo.mensaje),
            backgroundColor: theme.colorScheme.error,
          ),
        );
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
                  // Titulo
                  Text(
                    'Recuperar Contraseña',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu correo institucional para recuperar tu contraseña',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Campo de correo
                  CustomInputField(
                    label: 'Correo Institucional',
                    hintText: 'Tu correo institucional',
                    prefixIcon: Icons.email_outlined,
                    controller: _correoController,
                    validator: (valor){
                      if (valor == null || valor.isEmpty) {
                        return 'Por favor ingresa tu correo institucional';
                      }
                      if (!valor.contains('@') || !valor.endsWith('alumno.ipn.mx')) {
                        return 'Por favor ingresa un correo institucional válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
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
                    texto: 'Cambiar Contraseña',
                    onPressed: estaCargando ? null : _recuperacionContrasena,
                    cargando: estaCargando,
                    iconoInicio: Icons.password,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          context.pop();
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
        )
      )
    );
  }
}
