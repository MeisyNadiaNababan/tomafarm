// File: app_user.dart
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  static Future<Map<String, dynamic>?> getUserRole(String uid) async {
    try {
      // Untuk sementara, kita beri role 'farmer' secara default
      // Nanti bisa diganti dengan logika yang lebih kompleks
      final user = FirebaseAuth.instance.currentUser;
      
      return {
        'email': user?.email,
        'role': 'farmer', // Default ke farmer
        'status': 'active',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      };
      
    } catch (e) {
      print('Error getting user role: $e');
      return {
        'role': 'farmer',
        'status': 'active',
      };
    }
  }

  static bool isAdmin(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    return userData['role'] == 'admin';
  }
}