import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../services/user_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/avatar_helper.dart';
import 'custom_button.dart';
import 'custom_card.dart';
import 'custom_input.dart';

class EventComments extends StatefulWidget {
  final String eventId;

  const EventComments({
    super.key,
    required this.eventId,
  });

  @override
  State<EventComments> createState() => _EventCommentsState();
}

class _EventCommentsState extends State<EventComments> {
  final commentController = TextEditingController();
  final userService = UserService();

  bool isSending = false;

  Future<void> sendComment() async {
    final text = commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AppSnackbar.show(context, 'Você precisa estar logado.');
      return;
    }

    if (text.isEmpty) {
      AppSnackbar.show(context, 'Digite um comentário.');
      return;
    }

    try {
      setState(() {
        isSending = true;
      });

      final userData = await userService.getCurrentUserData();

      final nickname = userData['nickname'] ?? 'Usuário';
      final avatarStyle =
          userData['avatarStyle'] ?? AvatarHelper.defaultStyle;
      final avatarSeed =
          userData['avatarSeed'] ?? nickname.toString();

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('comments')
          .add({
        'text': text,
        'userId': user.uid,
        'userNickname': nickname,
        'avatarStyle': avatarStyle,
        'avatarSeed': avatarSeed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      commentController.clear();

      if (!mounted) return;

      AppSnackbar.show(context, 'Comentário enviado!');
    } catch (e) {
      AppSnackbar.show(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentários',
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),

          const SizedBox(height: 16),

          CustomInput(
            hint: 'Escreva um comentário',
            icon: Icons.comment,
            controller: commentController,
            maxLines: 2,
          ),

          const SizedBox(height: 12),

          CustomButton(
            text: isSending ? 'Enviando...' : 'Comentar',
            icon: Icons.send,
            onPressed: isSending ? () {} : sendComment,
          ),

          const SizedBox(height: 20),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .snapshots(),
            builder: (context, eventSnapshot) {
              final eventData =
                  eventSnapshot.data?.data() as Map<String, dynamic>?;

              final eventOwnerId = eventData?['createdBy'];
              final isEventOwner =
                  currentUserId != null && currentUserId == eventOwnerId;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(widget.eventId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Carregando comentários...',
                      style: AppTextStyles.subtitle,
                    );
                  }

                  if (docs.isEmpty) {
                    return Text(
                      'Nenhum comentário ainda.',
                      style: AppTextStyles.subtitle,
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final commentOwnerId = data['userId'];
                      final isCommentOwner =
                          currentUserId != null &&
                              currentUserId == commentOwnerId;

                      final canDelete = isCommentOwner || isEventOwner;

                      final nickname =
                          data['userNickname']?.toString() ?? 'Usuário';

                      final avatarStyle =
                          data['avatarStyle']?.toString() ??
                              AvatarHelper.defaultStyle;

                      final avatarSeed =
                          data['avatarSeed']?.toString() ?? nickname;

                      final avatarUrl = AvatarHelper.buildAvatarUrl(
                        style: avatarStyle,
                        seed: avatarSeed,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        nickname
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    data['text'] ?? '',
                                    style: AppTextStyles.subtitle,
                                  ),

                                  if (canDelete)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('events')
                                              .doc(widget.eventId)
                                              .collection('comments')
                                              .doc(doc.id)
                                              .delete();
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.danger,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}