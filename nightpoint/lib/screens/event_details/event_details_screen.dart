import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../map/real_map_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class EventDetailsScreen extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final String category;
  final String description;
  final double? latitude;
  final double? longitude;
  final String eventId;
  
  Future<void> openInGoogleMaps() async {
    if (latitude == null || longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    final canOpen = await canLaunchUrl(url);

    if (!canOpen) return;

    await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
    );
  }

  const EventDetailsScreen({
    super.key,
    required this.title,
    required this.location,
    required this.time,
    required this.category,
    required this.description,
    this.latitude,
    this.longitude,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes do Encontro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            CustomCard(
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

                  const SizedBox(height: 12),

                  Text(
                    title,
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.accent,
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

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: AppTextStyles.subtitle,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descrição',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    description.trim().isEmpty
                        ? 'Nenhuma descrição informada.'
                        : description,
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (latitude != null && longitude != null)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localização',
                      style: AppTextStyles.title.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Latitude: $latitude',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Longitude: $longitude',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
              if (latitude != null && longitude != null) ...[
                const SizedBox(height: 16),

                CustomCard(
                  child: SizedBox(
                    height: 240,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RealMapWidget(
                        latitude: latitude!,
                        longitude: longitude!,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              if (latitude != null && longitude != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: openInGoogleMaps,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Abrir no Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    final data = snapshot.data?.data() as Map<String, dynamic>?;

                    final participants = List<String>.from(
                      data?['participants'] ?? [],
                    );

                    final isParticipating =
                        userId != null && participants.contains(userId);

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: userId == null
                            ? null
                            : () async {
                                final ref = FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(eventId);

                                if (isParticipating) {
                                  await ref.update({
                                    'participants': FieldValue.arrayRemove([userId]),
                                  });
                                } else {
                                  await ref.update({
                                    'participants': FieldValue.arrayUnion([userId]),
                                  });
                                }
                              },
                        icon: Icon(
                          isParticipating
                              ? Icons.check_circle
                              : Icons.group_add,
                        ),
                        label: Text(
                          isParticipating
                              ? 'Participando'
                              : 'Participar do Encontro',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isParticipating
                              ? AppColors.accent
                              : AppColors.primary,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}