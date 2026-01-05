import 'dart:io';

import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

// Clase auxiliar para retornar URL y ruta de una imagen subida.
class _ResultadoSubida {
  final String url;
  final String ruta;

  const _ResultadoSubida({required this.url, required this.ruta});
}

// Repositorio abstracto para operaciones con eventos.
abstract class EventoRepository {
  // Crea un nuevo evento con sus imágenes y categorías.
  Future<EventModel> crearEvento({
    required String idOrganizador,
    required String nombre,
    required DateTime fecha,
    required String lugar,
    required bool entradaLibre,
    String? descripcion,
    File? imagen,
    File? flyer,
    required List<CategoriaModel> categorias,
  });

  // Obtiene los eventos de un organizador.
  Future<List<EventModel>> obtenerEventosPorOrganizador(String idOrganizador);

  // Sube una imagen al storage.
  Future<String?> subirImagen({
    required File archivo,
    required String idUsuario,
    required int idEvento,
    required bool esFlyer,
  });
}

// Implementación del repositorio de eventos usando Supabase.
class EventoRepositoryImpl implements EventoRepository {
  final SupabaseClient _supabase;
  static const String _bucket = 'escomevents_media';
  static const String _carpetaFlyers = 'flyers';
  static const String _carpetaPortadas = 'portadas';

  EventoRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<EventModel> crearEvento({
    required String idOrganizador,
    required String nombre,
    required DateTime fecha,
    required String lugar,
    required bool entradaLibre,
    String? descripcion,
    File? imagen,
    File? flyer,
    required List<CategoriaModel> categorias,
  }) async {
    int? idEvento;
    String? rutaImagen;
    String? rutaFlyer;

    try {
      // 1. Inserta el evento en la base de datos.
      final datosEvento = {
        'id_organizador': idOrganizador,
        'nombre': nombre,
        'fecha': fecha.toIso8601String(),
        'lugar': lugar,
        'entrada_libre': entradaLibre,
        'descripcion': descripcion,
        'validado': false,
      };

      final respuestaEvento = await _supabase
          .from('Evento')
          .insert(datosEvento)
          .select()
          .single();

      idEvento = (respuestaEvento['id_evento']) as int;

      // 2. Sube las imágenes si existen.
      String? urlImagen;
      String? urlFlyer;

      if (imagen != null) {
        final resultado = await _subirImagenConRuta(
          archivo: imagen,
          idUsuario: idOrganizador,
          idEvento: idEvento,
          esFlyer: false,
        );
        urlImagen = resultado.url;
        rutaImagen = resultado.ruta;
      }

      if (flyer != null) {
        final resultado = await _subirImagenConRuta(
          archivo: flyer,
          idUsuario: idOrganizador,
          idEvento: idEvento,
          esFlyer: true,
        );
        urlFlyer = resultado.url;
        rutaFlyer = resultado.ruta;
      }

      // 3. Actualiza el evento con las URLs de las imágenes.
      if (urlImagen != null || urlFlyer != null) {
        final actualizacion = <String, dynamic>{};
        if (urlImagen != null) actualizacion['imagen'] = urlImagen;
        if (urlFlyer != null) actualizacion['flyer'] = urlFlyer;

        await _supabase
            .from('Evento')
            .update(actualizacion)
            .eq('id_evento', idEvento);
      }

      // 4. Inserta las relaciones con categorías.
      if (categorias.isNotEmpty) {
        final relacionesCategorias = categorias
            .map((cat) => {
                  'id_evento': idEvento,
                  'id_categoria': cat.id,
                })
            .toList();

        await _supabase.from('Evento_Categoria').insert(relacionesCategorias);
      }

      // 5. Retorna el evento creado.
      return EventModel(
        id: idEvento,
        idOrganizador: idOrganizador,
        nombre: nombre,
        fecha: fecha,
        fechaCreacion: DateTime.now(),
        entradaLibre: entradaLibre,
        descripcion: descripcion,
        validado: false,
        imageUrl: urlImagen,
        lugar: lugar,
        flyer: urlFlyer,
        categorias: categorias,
      );
    } catch (e) {
      // Rollback: elimina los recursos creados en orden inverso.
      await _ejecutarRollback(
        idEvento: idEvento,
        rutaImagen: rutaImagen,
        rutaFlyer: rutaFlyer,
      );

      if (e is PostgrestException) {
        throw Exception('Error al crear evento: ${e.message}');
      } else if (e is StorageException) {
        throw Exception('Error al subir imagen: ${e.message}');
      }
      rethrow;
    }
  }

  // Ejecuta el rollback eliminando los recursos creados.
  Future<void> _ejecutarRollback({
    int? idEvento,
    String? rutaImagen,
    String? rutaFlyer,
  }) async {
    // 1. Elimina las imágenes del storage.
    final rutasAEliminar = <String>[
      if (rutaFlyer != null) rutaFlyer,
      if (rutaImagen != null) rutaImagen,
    ];

    if (rutasAEliminar.isNotEmpty) {
      try {
        await _supabase.storage.from(_bucket).remove(rutasAEliminar);
      } catch (_) {
        // Ignora errores al eliminar imágenes durante rollback.
      }
    }

    // 2. Elimina las relaciones evento-categoría.
    if (idEvento != null) {
      try {
        await _supabase
            .from('Evento_Categoria')
            .delete()
            .eq('id_evento', idEvento);
      } catch (_) {
        // Ignora errores al eliminar relaciones durante rollback.
      }

      // 3. Elimina el evento.
      try {
        await _supabase.from('Evento').delete().eq('id_evento', idEvento);
      } catch (_) {
        // Ignora errores al eliminar evento durante rollback.
      }
    }
  }

  // Sube una imagen y retorna tanto la URL como la ruta del archivo.
  Future<_ResultadoSubida> _subirImagenConRuta({
    required File archivo,
    required String idUsuario,
    required int idEvento,
    required bool esFlyer,
  }) async {
    final extension = path.extension(archivo.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nombreArchivo = '$timestamp$extension';
    final carpeta = esFlyer ? _carpetaFlyers : _carpetaPortadas;

    final rutaArchivo = '$carpeta/$idUsuario/$idEvento/$nombreArchivo';

    await _supabase.storage.from(_bucket).upload(
          rutaArchivo,
          archivo,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final urlPublica =
        _supabase.storage.from(_bucket).getPublicUrl(rutaArchivo);

    return _ResultadoSubida(url: urlPublica, ruta: rutaArchivo);
  }

  @override
  Future<String?> subirImagen({
    required File archivo,
    required String idUsuario,
    required int idEvento,
    required bool esFlyer,
  }) async {
    try {
      final extension = path.extension(archivo.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreArchivo = '$timestamp$extension';
      final carpeta = esFlyer ? _carpetaFlyers : _carpetaPortadas;

      // Ruta: flyers/userId/eventoId/timestamp.jpg
      // o: portadas/userId/eventoId/timestamp.jpg
      final rutaArchivo = '$carpeta/$idUsuario/$idEvento/$nombreArchivo';

      await _supabase.storage.from(_bucket).upload(
            rutaArchivo,
            archivo,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtiene la URL pública.
      final urlPublica = _supabase.storage.from(_bucket).getPublicUrl(rutaArchivo);

      return urlPublica;
    } on StorageException catch (e) {
      throw Exception('Error al subir imagen: ${e.message}');
    }
  }

  @override
  Future<List<EventModel>> obtenerEventosPorOrganizador(
    String idOrganizador,
  ) async {
    try {
      final respuesta = await _supabase
          .from('Evento')
          .select('''
            *,
            categorias:Evento_Categoria(
              categoria:Categoria(*)
            )
          ''')
          .eq('id_organizador', idOrganizador)
          .order('fecha', ascending: false);

      return (respuesta as List).map((json) {
        // Transforma las categorías anidadas.
        final categoriasRaw = json['categorias'] as List? ?? [];
        final categorias = categoriasRaw
            .map((ec) => ec['categoria'] as Map<String, dynamic>?)
            .where((c) => c != null)
            .map((c) => CategoriaModel.fromMap(c!))
            .toList();

        return EventModel.fromMap({
          ...json,
          'categorias': null, // Evita el parsing automático.
        }).copyWith(categorias: categorias);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener eventos: ${e.message}');
    }
  }
}
