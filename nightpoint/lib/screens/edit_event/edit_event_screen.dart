import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'Street';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.eventData['title'] ?? '';
    locationController.text = widget.eventData['location'] ?? '';
    timeController.text = widget.eventData['time'] ?? '';
    descriptionController.text = widget.eventData['description'] ?? '';
    category = widget.eventData['category'] ?? 'Street';
  }

  Future<void> updateEvent() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Preencha nome, local e horário.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .update({
      'title': titleController.text.trim(),
      'location': locationController.text.trim(),
      'time': timeController.text.trim(),
      'description': descriptionController.text.trim(),
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    AppSnackbar.show(context, 'Encontro atualizado!');
    Navigator.pop(context);

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Encontro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            CustomInput(
              hint: 'Nome do encontro',
              icon: Icons.drive_eta,
              controller: titleController,
            ),
            const SizedBox(height: 16),
            CustomInput(
              hint: 'Local',
              icon: Icons.location_on,
              controller: locationController,
            ),
            const SizedBox(height: 16),
            CustomInput(
              hint: 'Horário',
              icon: Icons.access_time,
              controller: timeController,
            ),
            const SizedBox(height: 16),
            CustomInput(
              hint: 'Descrição',
              icon: Icons.description,
              controller: descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Street', child: Text('Street')),
                DropdownMenuItem(value: 'JDM', child: Text('JDM')),
                DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                DropdownMenuItem(value: 'Drift', child: Text('Drift')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  category = value;
                });
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? 'Salvando...' : 'Salvar Alterações',
              icon: Icons.save,
              onPressed: isLoading ? () {} : updateEvent,
            ),
          ],
        ),
      ),
    );
  }
}