import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/ai_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/event_comments.dart';
import '../map/real_map_widget.dart';

class EventDetailsScreen extends StatefulWidget {
  final String title;
  final String location;
  final String time;
  final String category;
  final String description;
  final double? latitude;
  final double? longitude;
  final String eventId;
  final String creatorName;

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
    required this.creatorName,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final aiService = AiService();

  bool isGeneratingPost = false;
  String? generatedPost;

  Future<void> openInGoogleMaps() async {
    if (widget.latitude == null || widget.longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );

    final canOpen = await canLaunchUrl(url);

    if (!canOpen) return;

    await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
    );
  }

  Future<void> generateSharePost() async {
    try {
      setState(() {
        isGeneratingPost = true;
      });

      final post = await aiService.generateSharePost(
        title: widget.title,
        location: widget.location,
        time: widget.time,
        category: widget.category,
        description: widget.description,
      );

      if (!mounted) return;

      setState(() {
        generatedPost = post;
      });

      AppSnackbar.show(
        context,
        'Post gerado com IA!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingPost = false;
        });
      }
    }
  }

  Future<void> copyGeneratedPost() async {
    if (generatedPost == null || generatedPost!.trim().isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: generatedPost!),
    );

    if (!mounted) return;

    AppSnackbar.show(
      context,
      'Post copiado!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        widget.latitude != null && widget.longitude != null;

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
                    widget.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.title,
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
                          widget.location,
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
                        widget.time,
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
                    widget.description.trim().isEmpty
                        ? 'Nenhuma descrição informada.'
                        : widget.description,
                    style: AppTextStyles.subtitle,
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
                    'Divulgação com IA',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Gere um texto pronto para divulgar este encontro em grupos, stories ou redes sociais.',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 16),

                  CustomButton(
                    text: isGeneratingPost
                        ? 'Gerando post...'
                        : 'Gerar post de divulgação',
                    icon: Icons.auto_awesome,
                    onPressed:
                        isGeneratingPost ? () {} : generateSharePost,
                  ),

                  if (generatedPost != null) ...[
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Text(
                        generatedPost!,
                        style: AppTextStyles.subtitle,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: copyGeneratedPost,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar post'),
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
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            CustomCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Criado por: ${widget.creatorName}',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (hasLocation)
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
                      'Latitude: ${widget.latitude}',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Longitude: ${widget.longitude}',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),

            if (hasLocation) ...[
              const SizedBox(height: 16),

              CustomCard(
                child: SizedBox(
                  height: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RealMapWidget(
                      latitude: widget.latitude!,
                      longitude: widget.longitude!,
                      showUserMarker: false,
                      events: [
                        {
                          'id': widget.eventId,
                          'title': widget.title,
                          'location': widget.location,
                          'time': widget.time,
                          'category': widget.category,
                          'description': widget.description,
                          'latitude': widget.latitude,
                          'longitude': widget.longitude,
                          'creatorNickname': widget.creatorName,
                        },
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
            ],

            const SizedBox(height: 16),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                final data =
                    snapshot.data?.data() as Map<String, dynamic>?;

                final participants = List<String>.from(
                  data?['participants'] ?? [],
                );

                final isParticipating =
                    userId != null && participants.contains(userId);

                final likes = List<String>.from(
                  data?['likes'] ?? [],
                );

                final isLiked =
                    userId != null && likes.contains(userId);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${participants.length} participante(s)',
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    CustomCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: AppColors.danger,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '${likes.length} curtida(s)',
                            style: AppTextStyles.subtitle,
                          ),

                          const Spacer(),

                          IconButton(
                            onPressed: userId == null
                                ? null
                                : () async {
                                    final ref = FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(widget.eventId);

                                    if (isLiked) {
                                      await ref.update({
                                        'likes': FieldValue.arrayRemove(
                                          [userId],
                                        ),
                                      });
                                    } else {
                                      await ref.update({
                                        'likes': FieldValue.arrayUnion(
                                          [userId],
                                        ),
                                      });
                                    }
                                  },
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: userId == null
                            ? null
                            : () async {
                                final ref = FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(widget.eventId);

                                if (isParticipating) {
                                  await ref.update({
                                    'participants':
                                        FieldValue.arrayRemove([userId]),
                                  });
                                } else {
                                  await ref.update({
                                    'participants':
                                        FieldValue.arrayUnion([userId]),
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
                    ),

                    const SizedBox(height: 16),

                    EventComments(
                      eventId: widget.eventId,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}