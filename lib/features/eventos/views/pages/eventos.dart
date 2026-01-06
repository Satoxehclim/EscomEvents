import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_search_header.dart';
import 'package:escomevents_app/features/eventos/views/widgets/filtros_eventos.dart';
import 'package:flutter/material.dart';

// PANTALLA DE LISTA DE EVENTOS
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Estado de los filtros.
  FiltrosEventos _filtros = const FiltrosEventos();

  // Filtra y ordena los eventos.
  List<EventModel> _filtrarYOrdenarEventos(List<EventModel> eventos) {
    final ahora = DateTime.now();

    // Filtrar por estado (solo próximos, pasados y todos para estudiantes).
    List<EventModel> eventosFiltrados;
    switch (_filtros.filtroEstado) {
      case FiltroEstado.todos:
        eventosFiltrados =
            eventos.where((e) => e.validado).toList(); // Solo validados.
        break;
      case FiltroEstado.proximos:
        eventosFiltrados =
            eventos.where((e) => e.fecha.isAfter(ahora) && e.validado).toList();
        break;
      case FiltroEstado.pasados:
        eventosFiltrados = eventos
            .where((e) => e.fecha.isBefore(ahora) && e.validado)
            .toList();
        break;
      // Estos casos no deberían ocurrir en EventsScreen.
      case FiltroEstado.pendientes:
      case FiltroEstado.aprobados:
        eventosFiltrados = eventos.where((e) => e.validado).toList();
        break;
    }

    // TODO: Filtrar por categoría cuando se implemente.

    // Ordenar.
    switch (_filtros.ordenarPor) {
      case OrdenarPor.masRecientes:
        eventosFiltrados
            .sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        break;
      case OrdenarPor.masAntiguos:
        eventosFiltrados
            .sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        break;
      case OrdenarPor.masProximos:
        eventosFiltrados.sort((a, b) => a.fecha.compareTo(b.fecha));
        break;
      case OrdenarPor.masLejanos:
        eventosFiltrados.sort((a, b) => b.fecha.compareTo(a.fecha));
        break;
    }

    return eventosFiltrados;
  }

  // Muestra el modal de filtros.
  void _mostrarFiltros() {
    ModalFiltrosEventos.mostrar(
      context: context,
      filtrosActuales: _filtros,
      mostrarFiltrosAvanzados: false, // Solo filtros básicos para estudiantes.
      onAplicar: (nuevosFiltros) {
        setState(() => _filtros = nuevosFiltros);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Datos falsos para probar el diseño
    final List<EventModel> mockEvents = [
      EventModel(
        id: 1,
        idOrganizador: "org1",
        nombre: "Hackathon 2026: Innovación AI",
        fecha: DateTime(2026, 1, 6, 9, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: "Auditorio A",
        imageUrl:
            "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80",
      ),
      EventModel(
        id: 2,
        idOrganizador: "org2",
        nombre: "Taller de Flutter Avanzado",
        fecha: DateTime(2026, 1, 7, 14, 30),
        fechaCreacion: DateTime.now(),
        entradaLibre: false,
        validado: true,
        categorias: [],
        lugar: "Lab de Cómputo 3",
        imageUrl:
            "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80",
      ),
      EventModel(
        id: 3,
        idOrganizador: "org3",
        nombre: "Torneo de Fútbol Inter-ESCOM",
        fecha: DateTime(2026, 1, 8, 12, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: "Canchas Deportivas",
        imageUrl:
            "https://images.unsplash.com/photo-1579952363873-27f3bade8f55?auto=format&fit=crop&w=800&q=80",
      ),
      EventModel(
        id: 4,
        idOrganizador: "org3",
        nombre: "Conferencia de Ciberseguridad",
        fecha: DateTime(2024, 12, 20, 10, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: "Auditorio B",
        imageUrl:
            "https://images.unsplash.com/photo-1579952363873-27f3bade8f55?auto=format&fit=crop&w=800&q=80",
      ),
    ];

    final eventosFiltrados = _filtrarYOrdenarEventos(mockEvents);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header reutilizable con búsqueda y filtros.
            EventSearchHeader(
              onFilterTap: _mostrarFiltros,
            ),

            // Chips de filtro rápido.
            ChipsFiltroEstado(
              filtroSeleccionado: _filtros.filtroEstado,
              mostrarFiltrosAvanzados: false,
              onSeleccionar: (filtro) {
                setState(() {
                  _filtros = _filtros.copyWith(filtroEstado: filtro);
                });
              },
            ),

            // Título de sección.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _obtenerTituloSeccion(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            // Lista de eventos.
            Expanded(
              child: eventosFiltrados.isEmpty
                  ? _construirEstadoVacio()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: eventosFiltrados.length,
                      itemBuilder: (context, index) {
                        return EventCard(
                          event: eventosFiltrados[index],
                          onTap: () {
                            // TODO: Navegación al detalle.
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Obtiene el título de la sección según el filtro.
  String _obtenerTituloSeccion() {
    switch (_filtros.filtroEstado) {
      case FiltroEstado.todos:
        return 'Todos los Eventos';
      case FiltroEstado.proximos:
        return 'Próximos Eventos';
      case FiltroEstado.pasados:
        return 'Eventos Pasados';
      case FiltroEstado.pendientes:
      case FiltroEstado.aprobados:
        return 'Eventos';
    }
  }

  // Construye el estado vacío.
  Widget _construirEstadoVacio() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay eventos ${obtenerNombreFiltroEstado(_filtros.filtroEstado).toLowerCase()}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
