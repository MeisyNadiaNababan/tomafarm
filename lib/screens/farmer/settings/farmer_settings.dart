import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Load dari local storage - default true
    setState(() {
      _notificationsEnabled = true;
    });
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    // TODO: Save to local storage
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang TomaFarm'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TomaFarm - Smart Tomato Farming',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Aplikasi TomaFarm adalah sistem monitoring dan kontrol otomatis untuk budidaya tanaman tomat. '
                'Dilengkapi dengan berbagai fitur canggih untuk memastikan tanaman tomat tumbuh optimal.',
              ),
              SizedBox(height: 12),
              Text(
                'Fitur Utama:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Monitoring real-time sensor suhu, kelembapan, cahaya, dan tanah'),
              Text('• Kontrol otomatis dan manual pompa air & lampu tumbuh'),
              Text('• Riwayat data sensor dan aktivitas sistem'),
              Text('• Notifikasi kondisi tanaman'),
              SizedBox(height: 12),
              Text(
                'Versi: 1.0.0\nDikembangkan untuk Project Based Learning',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? user?.email?.split('@').first ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user?.emailVerified == true ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user?.emailVerified == true ? 'Email Terverifikasi' : 'Email Belum Diverifikasi',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.notifications,
                      title: 'Notifikasi',
                      subtitle: _notificationsEnabled ? 'Aktif' : 'Nonaktif',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: Colors.green,
                      ),
                      onTap: () => _toggleNotifications(!_notificationsEnabled),
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      icon: Icons.language,
                      title: 'Bahasa',
                      subtitle: 'Indonesia',
                      trailing: const Icon(Icons.check, color: Colors.green),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bahasa Indonesia aktif'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      icon: Icons.info,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Versi 1.0.0',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showAboutDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showLogoutConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.green, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}