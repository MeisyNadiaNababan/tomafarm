import 'package:flutter/material.dart';
import '../screens/admin/dashboard/admin_dashboard.dart';
import '../screens/admin/nodes/admin_nodes.dart';
import '../screens/admin/farmers/admin_farmers.dart';
import '../screens/admin/notifications/admin_notifications.dart';
import '../screens/admin/settings/admin_settings.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _currentIndex = 0;

  final List<Widget> _adminScreens = [
    const AdminDashboardScreen(),
    const AdminNodesScreen(),
    const AdminFarmersScreen(),
    const AdminNotificationsScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _adminScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Nodes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Petani',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}