import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/user_service.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/avatar_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../change_password/change_password_screen.dart';
import '../../services/ai_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentNickname;
  

  const EditProfileScreen({
    super.key,
    required this.currentNickname,
    
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nicknameController = TextEditingController();
  final avatarSeedController = TextEditingController();

  final userService = UserService();
  final random = Random();
  final List<String> seedWords = [
    'nightpoint',
    'nightdriver',
    'street',
    'turbo',
    'garage',
    'mugen',
    'boost',
    'neon',
    'driver',
    'racer',
    'point',
    'club',
    'bmw',
    'jdm',
    'premium',
    'crew',
    'track',
    'shift',
    'vibe',
    'meet',
  ];
  final aiService = AiService();
  int nextAvatarStyleIndex = 0;

  bool isGeneratingAvatar = false;
  bool isLoading = false;
  bool isLoadingProfile = true;

  String selectedAvatarStyle = AvatarHelper.defaultStyle;
  String getNextAvatarStyle() {
    final styles = AvatarHelper.styles;

    if (styles.isEmpty) {
      return AvatarHelper.defaultStyle;
    }

    final currentIndex = styles.indexOf(selectedAvatarStyle);

    if (currentIndex == -1) {
      nextAvatarStyleIndex = 0;
    } else {
      nextAvatarStyleIndex = currentIndex + 1;
    }

    if (nextAvatarStyleIndex >= styles.length) {
      nextAvatarStyleIndex = 0;
    }

    return styles[nextAvatarStyleIndex];
  }

  @override
  void initState() {
    super.initState();

    nicknameController.text = widget.currentNickname;
    avatarSeedController.text = widget.currentNickname;

    loadProfileData();
  }

  void randomizeAvatarSeed() {
    final word = seedWords[random.nextInt(seedWords.length)];
    final number = random.nextInt(99999);
    final randomStyle =
        AvatarHelper.styles[random.nextInt(AvatarHelper.styles.length)];

    setState(() {
      selectedAvatarStyle = randomStyle;
      avatarSeedController.text = '${word}_$number';
    });
  }
  Future<void> generateAvatarWithAi() async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      AppSnackbar.show(
        context,
        'Informe um nickname antes de gerar o avatar.',
      );

      return;
    }

    try {
      setState(() {
        isGeneratingAvatar = true;
      });

      final targetStyle = getNextAvatarStyle();

      final suggestion = await aiService.generateAvatarSuggestion(
        nickname: nickname,
        availableStyles: AvatarHelper.styles,
        forcedStyle: targetStyle,
        currentSeed: avatarSeedController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        selectedAvatarStyle = suggestion['style']!;
        avatarSeedController.text = suggestion['seed']!;
      });

      AppSnackbar.show(
        context,
        'Avatar gerado!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingAvatar = false;
        });
      }
    }
  }

  Future<void> loadProfileData() async {
    try {
      final data = await userService.getCurrentUserData();

      setState(() {
        nicknameController.text =
            data['nickname'] ?? widget.currentNickname;

        selectedAvatarStyle =
            data['avatarStyle'] ?? AvatarHelper.defaultStyle;

        avatarSeedController.text =
            data['avatarSeed'] ?? nicknameController.text.trim();

        isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        isLoadingProfile = false;
      });

      AppSnackbar.show(
        context,
        e.toString(),
      );
    }
  }

  Future<void> saveProfile() async {
    final nickname = nicknameController.text.trim();
    final avatarSeed = avatarSeedController.text.trim();

    if (nickname.isEmpty) {
      AppSnackbar.show(
        context,
        'Informe um nickname.',
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await userService.updateProfile(
        nickname: nickname,
        avatarStyle: selectedAvatarStyle,
        avatarSeed: avatarSeed.isEmpty ? nickname : avatarSeed,
      );

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Perfil atualizado!',
      );

      Navigator.pop(context);
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String get avatarUrl {
    return AvatarHelper.buildAvatarUrl(
      style: selectedAvatarStyle,
      seed: avatarSeedController.text.trim().isEmpty
          ? nicknameController.text.trim()
          : avatarSeedController.text.trim(),
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    avatarSeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView(
              children: [
                Text(
                  'Seu perfil',
                  style: AppTextStyles.title.copyWith(fontSize: 28),
                ),

                const SizedBox(height: 8),

                Text(
                  'Personalize seu nickname e avatar NightPoint.',
                  style: AppTextStyles.subtitle,
                ),

                const SizedBox(height: 24),

                Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.4,
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
                          return const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 58,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    AvatarHelper.formatStyleName(selectedAvatarStyle),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                CustomInput(
                  hint: 'Nickname',
                  icon: Icons.alternate_email,
                  controller: nicknameController,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedAvatarStyle,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(
                      Icons.face,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: AvatarHelper.styles.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(
                        AvatarHelper.formatStyleName(style),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedAvatarStyle = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                CustomInput(
                  hint: 'Seed do avatar',
                  icon: Icons.casino,
                  controller: avatarSeedController,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: isGeneratingAvatar ? null : generateAvatarWithAi,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      isGeneratingAvatar ? 'Gerando avatar...' : 'Gerar avatar com IA',
                    ),
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

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: randomizeAvatarSeed,
                    icon: const Icon(Icons.casino),
                    label: const Text('Randomizar Avatar'),
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

                const SizedBox(height: 8),

                Text(
                  'A seed muda o desenho do avatar. Teste nomes como pablo, bmw320i, nightdriver ou mugen.',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: isLoading ? 'Salvando...' : 'Salvar Perfil',
                  icon: Icons.save,
                  onPressed: isLoading ? () {} : saveProfile,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Alterar Senha'),
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
        ),
      ),
    );
  }
}