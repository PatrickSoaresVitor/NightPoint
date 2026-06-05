import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../edit_event/edit_event_screen.dart';
import '../event_details/event_details_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final searchController = TextEditingController();
  final aiService = AiService();

  String selectedCategory = 'Todos';
  String searchText = '';

  bool isGeneratingRecommendation = false;
  String? aiRecommendation;

  final categories = const [
    'Todos',
    'Street',
    'JDM',
    'Premium',
    'Drift',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> filterEvents(
    List<Map<String, dynamic>> events,
  ) {
    return events.where((event) {
      final title = (event['title'] ?? '').toString().toLowerCase();
      final location = (event['location'] ?? '').toString().toLowerCase();
      final category = (event['category'] ?? '').toString().toLowerCase();
      final description =
          (event['description'] ?? '').toString().toLowerCase();

      final query = searchText.toLowerCase().trim();

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          location.contains(query) ||
          category.contains(query) ||
          description.contains(query);

      final matchesCategory = selectedCategory == 'Todos' ||
          category == selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> generateRecommendation(
    List<Map<String, dynamic>> events,
  ) async {
    if (events.isEmpty) {
      AppSnackbar.show(
        context,
        'Não há eventos para recomendar.',
      );
      return;
    }

    try {
      setState(() {
        isGeneratingRecommendation = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      Map<String, dynamic>? garage;

      if (user != null) {
        final garageDoc = await FirebaseFirestore.instance
            .collection('garages')
            .doc(user.uid)
            .get();

        if (garageDoc.exists) {
          garage = garageDoc.data();
        }
      }

      final position = await LocationService.getCurrentPosition();

      final userLatitude = position.latitude;
      final userLongitude = position.longitude;

      final now = DateTime.now();

      final eventsWithDistance = events.map((event) {
        final latitudeValue = event['latitude'];
        final longitudeValue = event['longitude'];

        double? distanceKm;

        if (latitudeValue != null && longitudeValue != null) {
          final eventLatitude = (latitudeValue as num).toDouble();
          final eventLongitude = (longitudeValue as num).toDouble();

          final distanceMeters = Geolocator.distanceBetween(
            userLatitude,
            userLongitude,
            eventLatitude,
            eventLongitude,
          );

          distanceKm = distanceMeters / 1000;
        }

        return {
          ...event,
          'distanceKm': distanceKm,
          'distanceKmText': distanceKm == null
              ? 'Não calculada'
              : '${distanceKm.toStringAsFixed(1)} km',
        };
      }).toList();

      eventsWithDistance.sort((a, b) {
        final distanceA = a['distanceKm'] as double?;
        final distanceB = b['distanceKm'] as double?;

        if (distanceA == null && distanceB == null) return 0;
        if (distanceA == null) return 1;
        if (distanceB == null) return -1;

        return distanceA.compareTo(distanceB);
      });

      final recommendation = await aiService.recommendEvents(
        events: eventsWithDistance,
        garage: garage,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        currentDateTime: now,
      );

      if (!mounted) return;

      setState(() {
        aiRecommendation = recommendation;
      });

      AppSnackbar.show(
        context,
        'Recomendação gerada com IA!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingRecommendation = false;
        });
      }
    }
  }

  void openEventDetails(
    Map<String, dynamic> event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          title: event['title'] ?? 'Sem título',
          location: event['location'] ?? 'Local não informado',
          date: event['date'] ?? 'Data não informada',
          time: event['time'] ?? 'Horário não informado',
          category: event['category'] ?? 'Evento',
          description: event['description'] ?? '',
          latitude: event['latitude'],
          longitude: event['longitude'],
          eventId: event['id'],
          creatorName: event['creatorNickname'] ??
              event['creatorEmail'] ??
              'Criador não informado',
        ),
      ),
    );
  }

  void openEditEvent(
    Map<String, dynamic> event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventScreen(
          eventId: event['id'],
          eventData: event,
        ),
      ),
    );
  }

  Future<void> toggleLike({
    required String eventId,
    required bool isLiked,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AppSnackbar.show(
        context,
        'Faça login para curtir.',
      );
      return;
    }

    final eventRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId);

    if (isLiked) {
      await eventRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await eventRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> toggleParticipation({
    required String eventId,
    required bool isParticipating,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AppSnackbar.show(
        context,
        'Faça login para participar.',
      );
      return;
    }

    final eventRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId);

    if (isParticipating) {
      await eventRef.update({
        'participants': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await eventRef.update({
        'participants': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .delete();

    if (!mounted) return;

    AppSnackbar.show(
      context,
      'Evento excluído.',
    );
  }

  Future<void> confirmDeleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Excluir evento',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja excluir este evento?',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteEvent(eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eventos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Pesquisar eventos...',
                hintStyle: AppTextStyles.subtitle,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                ),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar eventos.',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.separated(
                      itemCount: 3,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, __) {
                        return CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: 180,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final allEvents = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return {
                      'id': doc.id,
                      ...data,
                    };
                  }).toList();

                  if (allEvents.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum evento publicado ainda.',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }

                  final filteredEvents = filterEvents(allEvents);

                  return ListView(
                    children: [
                      CustomButton(
                        text: isGeneratingRecommendation
                            ? 'Gerando recomendação...'
                            : 'Recomendar eventos com IA',
                        icon: Icons.auto_awesome,
                        onPressed: isGeneratingRecommendation
                            ? () {}
                            : () => generateRecommendation(filteredEvents),
                      ),

                      if (aiRecommendation != null) ...[
                        const SizedBox(height: 16),

                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recomendação por localização e horário',
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 22,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                aiRecommendation!,
                                style: AppTextStyles.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      if (filteredEvents.isEmpty)
                        CustomCard(
                          child: Text(
                            'Nenhum evento encontrado com esses filtros.',
                            style: AppTextStyles.subtitle,
                          ),
                        )
                      else
                        ...filteredEvents.map((event) {
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;

                          final isOwner =
                              event['createdBy'] == currentUserId;

                          final participants = List<String>.from(
                            event['participants'] ?? [],
                          );

                          final likes = List<String>.from(
                            event['likes'] ?? [],
                          );

                          final isLiked = currentUserId != null &&
                              likes.contains(currentUserId);

                          final isParticipating = currentUserId != null &&
                              participants.contains(currentUserId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () {
                                openEventDetails(event);
                              },
                              child: EventCard(
                                id: event['id'],
                                title: event['title'] ?? 'Sem título',
                                location: event['location'] ??
                                    'Local não informado',
                                date: event['date'] ??
                                    'Data não informada',
                                time: event['time'] ??
                                    'Horário não informado',
                                category:
                                    event['category'] ?? 'Evento',
                                description:
                                    event['description'] ?? '',
                                isOwner: isOwner,
                                participantsCount: participants.length,
                                likesCount: likes.length,
                                isLiked: isLiked,
                                isParticipating: isParticipating,
                                onEdit: () {
                                  openEditEvent(event);
                                },
                                onDelete: () {
                                  confirmDeleteEvent(event['id']);
                                },
                                onLike: () {
                                  toggleLike(
                                    eventId: event['id'],
                                    isLiked: isLiked,
                                  );
                                },
                                onParticipate: () {
                                  toggleParticipation(
                                    eventId: event['id'],
                                    isParticipating: isParticipating,
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                    ],
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

class EventCard extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String date;
  final String time;
  final String category;
  final String description;
  final bool isOwner;
  final int participantsCount;
  final int likesCount;
  final bool isLiked;
  final bool isParticipating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback onParticipate;

  const EventCard({
    super.key,
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.category,
    required this.description,
    required this.isOwner,
    required this.participantsCount,
    required this.likesCount,
    required this.isLiked,
    required this.isParticipating,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    required this.onParticipate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              if (isOwner)
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ];
                  },
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.accent,
                size: 18,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  location,
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: AppColors.primary,
                size: 18,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '$date • $time',
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.groups,
                color: AppColors.primary,
                size: 18,
              ),

              const SizedBox(width: 8),

              Text(
                '$participantsCount participante(s)',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppColors.danger : AppColors.danger,
                size: 18,
              ),

              const SizedBox(width: 8),

              Text(
                '$likesCount curtida(s)',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),

          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),

            Text(
              description,
              style: AppTextStyles.subtitle,
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(
                    isLiked ? 'Curtido' : 'Curtir',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(
                      color: AppColors.danger,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onParticipate,
                  icon: Icon(
                    isParticipating
                        ? Icons.check_circle
                        : Icons.group_add,
                    size: 18,
                  ),
                  label: Text(
                    isParticipating
                        ? 'Participando'
                        : 'Participar',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}