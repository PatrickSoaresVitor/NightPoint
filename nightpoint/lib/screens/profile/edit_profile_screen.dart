import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/user_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

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
  final userService = UserService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nicknameController.text = widget.currentNickname;
  }

  Future<void> saveNickname() async {
    if (nicknameController.text.trim().isEmpty) {
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

      await userService.updateNickname(
        nickname: nicknameController.text.trim(),
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

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            Text(
              'Seu nickname',
              style: AppTextStyles.title.copyWith(fontSize: 28),
            ),

            const SizedBox(height: 8),

            Text(
              'Esse nome será exibido em comentários e eventos.',
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(height: 24),

            CustomInput(
              hint: 'Nickname',
              icon: Icons.alternate_email,
              controller: nicknameController,
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: isLoading ? 'Salvando...' : 'Salvar Perfil',
              icon: Icons.save,
              onPressed: isLoading ? () {} : saveNickname,
            ),
          ],
        ),
      ),
    );
  }
}