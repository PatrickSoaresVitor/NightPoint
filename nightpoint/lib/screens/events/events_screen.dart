import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../event_details/event_details_screen.dart';
import '../edit_event/edit_event_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eventos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Container(
                          width: 80,  
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: 180,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'Nenhum evento publicado ainda.',
                  style: AppTextStyles.subtitle,
                ),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isOwner = data['createdBy'] == currentUserId;
                final participants = List<String>.from(
                  data['participants'] ?? [],
                );
                final likes = List<String>.from(
                  data['likes'] ?? [],
                );
                final isLiked = currentUserId != null && likes.contains(currentUserId);
                final isParticipating =
                  currentUserId != null && participants.contains(currentUserId);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(
                          title: data['title'] ?? 'Sem título',
                          location: data['location'] ?? 'Local não informado',
                          time: data['time'] ?? 'Horário não informado',
                          category: data['category'] ?? 'Evento',
                          description: data['description'] ?? '',
                          latitude: data['latitude'],
                          longitude: data['longitude'],
                          eventId: docs[index].id,
                          creatorEmail: data['creatorEmail'] ?? 'Criador não informado',
                          
                        ),
                      ),
                    );
                  },
                  child: EventCard(
                    id: docs[index].id,
                    title: data['title'] ?? 'Sem título',
                    location: data['location'] ?? 'Local não informado',
                    time: data['time'] ?? 'Horário não informado',
                    category: data['category'] ?? 'Evento',
                    description: data['description'] ?? '',
                    isOwner: isOwner,
                    participantsCount: participants.length,
                    likesCount: likes.length,
                    isLiked: isLiked,
                    isParticipating: isParticipating,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final String category;
  final String description;
  final String id;
  final bool isOwner;
  final int participantsCount;
  final int likesCount;
  final bool isLiked;
  final bool isParticipating;
  

  const EventCard({
    super.key,
    required this.title,
    required this.location,
    required this.time,
    required this.category,
    required this.description,
    required this.id,
    required this.isOwner,
    required this.participantsCount,
    required this.likesCount,
    required this.isLiked,
    required this.isParticipating,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(location, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(time, style: AppTextStyles.subtitle),
            ],
          ),
          
          const SizedBox(height: 8), 
          Row(
            children: [
              Icon(
                isParticipating ? Icons.check_circle : Icons.groups,
                color: isParticipating
                    ? AppColors.accent
                    : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isParticipating
                    ? '$participantsCount participante(s) • Você vai'
                    : '$participantsCount participante(s)',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '$likesCount curtida(s)',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),

          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextStyles.subtitle,
            ),
          ],
          

          const SizedBox(height: 12),

          if (isOwner) ...[
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditEventScreen(
                          eventId: id,
                          eventData: {
                            'title': title,
                            'location': location,
                            'time': time,
                            'description': description,
                            'category': category,
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                  ),
                ),

                IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Excluir encontro'),
                          content: const Text(
                            'Tem certeza que deseja excluir este encontro?',
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

                    if (confirm != true) return;

                    await FirebaseFirestore.instance
                        .collection('events')
                        .doc(id)
                        .delete();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}