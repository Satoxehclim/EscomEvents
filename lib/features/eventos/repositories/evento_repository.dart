import 'dart:io';

import 'package:escomevents_app/features/eventos/models/categoria_model.dart';
import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/models/filtro_eventos_model.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

// Clase auxiliar para retornar URL y ruta de una imagen subida.
class _ResultadoSubida {
  final String url;
  final String ruta;

  const _ResultadoSubida({required this.url, required this.ruta});
}

// Resultado paginado que incluye los datos y si hay más páginas.
class ResultadoPaginado<T> {
  final List<T> datos;
  final bool hayMas;
  final int paginaActual;

  const ResultadoPaginado({
    required this.datos,
    required this.hayMas,
    required this.paginaActual,
  });
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

  // Elimina un evento y todos sus recursos asociados.
  Future<void> eliminarEvento(EventModel evento);

  // Obtiene los eventos de un organizador con paginación y filtros.
  Future<ResultadoPaginado<EventModel>> obtenerEventosPorOrganizador(
    String idOrganizador, {
    int pagina = 0,
    int tamanoPagina = 10,
    FiltroEventos? filtros,
  });

  // Sube una imagen al storage.
  Future<String?> subirImagen({
    required File archivo,
    required String idUsuario,
    required int idEvento,
    required bool esFlyer,
  });

  // Obtiene el nombre del organizador por su ID.
  Future<String?> obtenerNombreOrganizador(String idOrganizador);
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
      // Inserta el evento en la base de datos.
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

      // Sube las imágenes si existen.
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

      // Actualiza el evento con las URLs de las imágenes.
      if (urlImagen != null || urlFlyer != null) {
        final actualizacion = <String, dynamic>{};
        if (urlImagen != null) actualizacion['imagen'] = urlImagen;
        if (urlFlyer != null) actualizacion['flyer'] = urlFlyer;

        await _supabase
            .from('Evento')
            .update(actualizacion)
            .eq('id_evento', idEvento);
      }

      // Inserta las relaciones con categorías.
      if (categorias.isNotEmpty) {
        final relacionesCategorias = categorias
            .map((cat) => {
                  'id_evento': idEvento,
                  'id_categoria': cat.id,
                })
            .toList();

        await _supabase.from('Evento_Categoria').insert(relacionesCategorias);
      }

      // Retorna el evento creado.
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
    // Elimina las imágenes del storage.
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

    // Elimina las relaciones evento-categoría.
    if (idEvento != null) {
      try {
        await _supabase
            .from('Evento_Categoria')
            .delete()
            .eq('id_evento', idEvento);
      } catch (_) {
        // Ignora errores al eliminar relaciones durante rollback.
      }

      // Elimina el evento.
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
  Future<ResultadoPaginado<EventModel>> obtenerEventosPorOrganizador(
    String idOrganizador, {
    int pagina = 0,
    int tamanoPagina = 10,
    FiltroEventos? filtros,
  }) async {
    try {
      final desde = pagina * tamanoPagina;
      final hasta = desde + tamanoPagina - 1;
      final ahora = DateTime.now().toIso8601String();

      // Construye el query base.
      var query = _supabase.from('Evento').select('''
            *,
            categorias:Evento_Categoria(
              categoria:Categoria(*)
            )
          ''').eq('id_organizador', idOrganizador);

      // Aplica filtros de estado.
      switch (filtros?.estado) {
        case FiltroEstado.proximos:
          query = query.gte('fecha', ahora);
          break;
        case FiltroEstado.pasados:
          query = query.lt('fecha', ahora).eq('validado', true);
          break;
        case FiltroEstado.pendientes:
          query = query.eq('validado', false);
          break;
        case FiltroEstado.aprobados:
          query = query.eq('validado', true);
          break;
        case FiltroEstado.todos:
        case null:
          // Sin filtro de estado.
          break;
      }

      // Filtra por categoría si está especificada.
      if (filtros?.idCategoria != null) {
        // Obtiene los ids de eventos que tienen la categoría.
        final eventosConCategoria = await _supabase
            .from('Evento_Categoria')
            .select('id_evento')
            .eq('id_categoria', filtros!.idCategoria!);

        final idsEventos = (eventosConCategoria as List)
            .map((e) => e['id_evento'] as int)
            .toList();

        if (idsEventos.isEmpty) {
          // No hay eventos con esa categoría.
          return ResultadoPaginado(
            datos: [],
            hayMas: false,
            paginaActual: pagina,
          );
        }

        query = query.inFilter('id_evento', idsEventos);
      }

      // Determina el ordenamiento.
      final orden = filtros?.orden ?? OrdenEvento.masRecientes;
      String columnaOrden;
      bool ascendente;

      switch (orden) {
        case OrdenEvento.masRecientes:
          columnaOrden = 'created_at';
          ascendente = false;
          break;
        case OrdenEvento.masAntiguos:
          columnaOrden = 'created_at';
          ascendente = true;
          break;
        case OrdenEvento.masProximos:
          columnaOrden = 'fecha';
          ascendente = true;
          break;
        case OrdenEvento.masLejanos:
          columnaOrden = 'fecha';
          ascendente = false;
          break;
      }

      // Aplica ordenamiento y paginación.
      final respuesta = await query
          .order(columnaOrden, ascending: ascendente)
          .range(desde, hasta);

      final eventos = (respuesta as List).map((json) {
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

      // Si obtuvimos menos eventos que el tamaño de página, no hay más.
      final hayMas = eventos.length == tamanoPagina;

      return ResultadoPaginado(
        datos: eventos,
        hayMas: hayMas,
        paginaActual: pagina,
      );
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener eventos: ${e.message}');
    }
  }

  @override
  Future<String?> obtenerNombreOrganizador(String idOrganizador) async {
    try {
      final respuesta = await _supabase
          .from('Perfil')
          .select('nombre')
          .eq('id_perfil', idOrganizador)
          .maybeSingle();

      if (respuesta == null) return null;
      return respuesta['nombre'] as String?;
    } on PostgrestException {
      return null;
    }
  }

  // Elimina una imagen del storage usando su URL pública.
  Future<void> _eliminarImagenDeUrl(String urlPublica) async {
    try {
      // Extrae la ruta del archivo de la URL.
      // URL formato: https://...supabase.co/storage/v1/object/public/bucket/path
      final uri = Uri.parse(urlPublica);
      final pathSegments = uri.pathSegments;
      
      // Busca el índice del bucket y obtiene la ruta después de él.
      final bucketIndex = pathSegments.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final rutaArchivo = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucket).remove([rutaArchivo]);
      }
    } catch (_) {
      // Ignora errores al eliminar imágenes.
    }
  }

  @override
  Future<void> eliminarEvento(EventModel evento) async {
    try {
      // Elimina el evento de la base de datos.
      await _supabase.from('Evento').delete().eq('id_evento', evento.id);

      // Elimina las imágenes del storage al final.
      // Esto asegura que la eliminación de BD fue exitosa antes de borrar archivos.
      if (evento.imageUrl != null) {
        await _eliminarImagenDeUrl(evento.imageUrl!);
      }
      if (evento.flyer != null) {
        await _eliminarImagenDeUrl(evento.flyer!);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar evento: ${e.message}');
    } on StorageException catch (e) {
      throw Exception('Error al eliminar archivos: ${e.message}');
    }
  }
}
