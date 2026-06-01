import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../event_details/event_details_screen.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Eventos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            MyEventSection(
              title: 'Criados por mim',
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('createdBy', isEqualTo: userId)
                  .snapshots(),
            ),

            const SizedBox(height: 24),

            MyEventSection(
              title: 'Estou participando',
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('participants', arrayContains: userId)
                  .snapshots(),
            ),

            const SizedBox(height: 24),

            MyEventSection(
              title: 'Curtidos',
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('likes', arrayContains: userId)
                  .snapshots(),
            ),
          ],
        ),
      ),
    );
  }
}

class MyEventSection extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;

  const MyEventSection({
    super.key,
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),

          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Carregando...',
                  style: AppTextStyles.subtitle,
                );
              }

              if (docs.isEmpty) {
                return Text(
                  'Nenhum evento encontrado.',
                  style: AppTextStyles.subtitle,
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailsScreen(
                              eventId: doc.id,
                              title: data['title'] ?? 'Sem título',
                              location: data['location'] ?? 'Local não informado',
                              time: data['time'] ?? 'Horário não informado',
                              category: data['category'] ?? 'Evento',
                              description: data['description'] ?? '',
                              latitude: data['latitude'],
                              longitude: data['longitude'],
                              creatorEmail: data['creatorEmail'] ?? 'Criador não informado',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event,
                              color: AppColors.primary,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                data['title'] ?? 'Sem título',
                                style: AppTextStyles.subtitle,
                              ),
                            ),

                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}