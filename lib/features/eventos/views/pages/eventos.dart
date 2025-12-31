import 'package:escomevents_app/features/eventos/models/evento_model.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_card.dart';
import 'package:escomevents_app/features/eventos/views/widgets/evento_search_header.dart';
import 'package:flutter/material.dart';

// PANTALLA DE LISTA DE EVENTOS
class EventsScreen extends StatelessWidget {
  const EventsScreen({Key? key}) : super(key: key);

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
        imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80",
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
        imageUrl: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80",
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
        imageUrl: "https://images.unsplash.com/photo-1579952363873-27f3bade8f55?auto=format&fit=crop&w=800&q=80",
      ),
      EventModel(
        id: 4,
        idOrganizador: "org3",
        nombre: "Torneo de Fútbol Inter-ESCOM",
        fecha: DateTime(2026, 1, 8, 12, 0),
        fechaCreacion: DateTime.now(),
        entradaLibre: true,
        validado: true,
        categorias: [],
        lugar: "Canchas Deportivas",
        imageUrl: "https://images.unsplash.com/photo-1579952363873-27f3bade8f55?auto=format&fit=crop&w=800&q=80",
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header reutilizable
            EventSearchHeader(
              onFilterTap: () {
                // Acción del filtro (a implementar luego)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Filtros próximamente")),
                );
              },
            ),
            
            // Título de sección (opcional)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Próximos Eventos",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Lista de eventos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockEvents.length,
                itemBuilder: (context, index) {
                  return EventCard(
                    event: mockEvents[index],
                    onTap: () {
                      // Navegación al detalle
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
}
