import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';

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
        child: ListView(
          children: const [
            EventCard(
              title: 'Night Meet Franca',
              location: 'Posto GT',
              time: 'Hoje • 22:30',
              category: 'Street',
            ),

            SizedBox(height: 16),

            EventCard(
              title: 'Euro Night',
              location: 'Av. Champagnat',
              time: 'Sábado • 21:00',
              category: 'Premium',
            ),

            SizedBox(height: 16),

            EventCard(
              title: 'JDM Point',
              location: 'Shopping',
              time: 'Domingo • 20:00',
              category: 'JDM',
            ),
          ],
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

  const EventCard({
    super.key,
    required this.title,
    required this.location,
    required this.time,
    required this.category,
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
        ],
      ),
    );
  }
}