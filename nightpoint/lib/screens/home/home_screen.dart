import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../events/events_screen.dart';
import '../garage/garage_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int currentIndex = 0;

  final List<Widget> pages = [
    const MapScreen(),
    const EventsScreen(),
    const GarageScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.garage),
            label: 'Garagem',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}