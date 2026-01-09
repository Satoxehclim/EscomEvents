import 'package:escomevents_app/core/view/widgets/custom_form_field.dart';
import 'package:escomevents_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerfilPage extends ConsumerStatefulWidget {
  const PerfilPage({super.key});

  @override
  ConsumerState<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends ConsumerState<PerfilPage> {
  // 1. VARIABLES DE ESTADO
  final TextEditingController _nombreController = TextEditingController();
  
  // Inicia en false para que empiece en "Modo Lectura" (bloqueado)
  bool _isEditing = false; 
  bool _cargando = false; // Para saber si está subiendo datos
  File? _imagenNueva;

  @override
  void initState() {
    super.initState();
    // Leemos el valor inicial solo una vez al cargar la pantalla
    final perfilInicial = ref.read(perfilActualProvider);
    _nombreController.text = perfilInicial?.nombre ?? '';
  }

  // 2. FUNCIÓN PARA SELECCIONAR IMAGEN
  Future<void> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagenNueva = File(image.path);
      });
    }
  }

  // 3. FUNCIÓN PARA GUARDAR CAMBIOS
  Future<void> guardarCambios() async {
    
    final perfilActual = ref.read(perfilActualProvider);
    if (perfilActual == null) return;

    setState(() {
      _cargando = true; // Activamos spinner
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? urlFinal = perfilActual.avatar; 

      // A) ¿Hay imagen nueva? -> SUBIR
      if (_imagenNueva != null) {
        final String extension = _imagenNueva!.path.split('.').last;
        final String rutaArchivo = 'avatares/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await Supabase.instance.client.storage
            .from('escomevents_media')
            .upload(
              rutaArchivo,
              _imagenNueva!,
              fileOptions: const FileOptions(upsert: true),
            );

        urlFinal = Supabase.instance.client.storage
            .from('escomevents_media')
            .getPublicUrl(rutaArchivo);
      }

      // B) ACTUALIZAR BASE DE DATOS
      await Supabase.instance.client
          .from('Perfil')
          .update({
            'nombre': _nombreController.text.trim(),
            'avatar': urlFinal,
          })
          .eq('id_perfil', userId);

      // C) ACTUALIZAR AUTH (Metadata)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'nombre': _nombreController.text.trim()
          },
        ),
      );

      // D) REFRESCO AUTOMÁTICO
      ref.invalidate(perfilActualProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil guardado correctamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Al terminar, salimos del modo edición
      if (mounted) {
        setState(() {
          _isEditing = false; 
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false; // Apagamos spinner
          _imagenNueva = null; 
        });
      }
    }
  }

  // 4. INTERFAZ GRÁFICA (BUILD)
  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en tiempo real
    final perfil = ref.watch(perfilActualProvider);

    if (perfil == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 8),
              Text('Perfil'),
            ],
          ),
        ),
        
        // BOTÓN FLOTANTE INTELIGENTE
        floatingActionButton: FloatingActionButton(
          onPressed: _cargando 
            ? null // Si carga, no hace nada
            : () {
                if (_isEditing) {
                  // Si estaba editando, ahora GUARDAMOS
                  guardarCambios();
                } else {
                  // Si estaba leyendo, activamos MODO EDICIÓN
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
          child: _cargando 
              ? const CircularProgressIndicator(color: Colors.white)
              : Icon(_isEditing ? Icons.save : Icons.edit),
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  
                  // --- AVATAR ---
                  GestureDetector(
                    // Solo permite clic si estamos editando
                    onTap: _isEditing ? seleccionarImagen : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 180, 
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              // Borde azul solo si se puede editar
                              color: _isEditing ? Colors.blueAccent : Colors.transparent, 
                              width: 3,
                            ),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: _imagenNueva != null
                                  ? FileImage(_imagenNueva!) as ImageProvider
                                  : (perfil.avatar != null && perfil.avatar!.isNotEmpty)
                                      ? NetworkImage(perfil.avatar!)
                                      : const AssetImage('assets/icon/icon.png'),
                            ),
                          ),
                        ),
                        
                        // Icono de camarita (solo visible si editamos)
                        if (_isEditing)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- FORMULARIO ---
                  Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomInputField(
                          label: 'Nombre',
                          hintText: 'Nombre completo',
                          controller: _nombreController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.person,
                          // IMPORTANTE: Si NO estoy editando (!), es readOnly
                          readOnly: !_isEditing, 
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // --- QR ---
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: QrImageView(
                              data: perfil.idPerfil,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              semanticsLabel: 'Código QR de usuario',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(child: Text("Tu código de acceso")),
                      ],
                    ),
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