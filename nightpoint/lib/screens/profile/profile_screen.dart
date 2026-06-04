import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/avatar_helper.dart';
import '../../widgets/custom_card.dart';
import '../auth/login_screen.dart';
import '../my_events/my_events_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final userService = UserService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            CustomCard(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: userService.getCurrentUserProfile(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();

                      final nickname =
                          data?['nickname']?.toString() ?? 'Usuário';

                      final avatarStyle =
                          data?['avatarStyle']?.toString() ??
                              AvatarHelper.defaultStyle;

                      final avatarSeed =
                          data?['avatarSeed']?.toString() ??
                              nickname;

                      final avatarUrl = AvatarHelper.buildAvatarUrl(
                        style: avatarStyle,
                        seed: avatarSeed,
                      );

                      return Column(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.18),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      nickname
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            AvatarHelper.formatStyleName(avatarStyle),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            nickname,
                            style: AppTextStyles.title.copyWith(
                              fontSize: 26,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            user?.email ?? 'E-mail não informado',
                            style: AppTextStyles.subtitle,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      currentNickname: nickname,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar Perfil'),
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
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .where('createdBy', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, createdSnapshot) {
                      final eventsCount =
                          createdSnapshot.data?.docs.length ?? 0;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('events')
                            .where(
                              'participants',
                              arrayContains: user?.uid,
                            )
                            .snapshots(),
                        builder: (context, participatingSnapshot) {
                          final participatingCount =
                              participatingSnapshot.data?.docs.length ?? 0;

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('events')
                                .where(
                                  'likes',
                                  arrayContains: user?.uid,
                                )
                                .snapshots(),
                            builder: (context, likesSnapshot) {
                              final likesCount =
                                  likesSnapshot.data?.docs.length ?? 0;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ProfileStat(
                                    label: 'Criados',
                                    value: eventsCount.toString(),
                                  ),
                                  ProfileStat(
                                    label: 'Participando',
                                    value: participatingCount.toString(),
                                  ),
                                  ProfileStat(
                                    label: 'Curtidos',
                                    value: likesCount.toString(),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyEventsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.event_note),
                label: const Text('Meus Eventos'),
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

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authService.logout();

                  if (!context.mounted) return;

                  AppSnackbar.show(
                    context,
                    'Você saiu da conta.',
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(
                    color: AppColors.danger,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const ProfileStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}

class BadgeChip extends StatelessWidget {
  final String text;

  const BadgeChip({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      side: const BorderSide(
        color: AppColors.border,
      ),
    );
  }
}