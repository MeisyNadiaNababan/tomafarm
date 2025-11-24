import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/home_screen.dart';
import 'auth/signin_screen.dart'; // Tambahkan ini
import 'auth/signup_screen.dart'; // Tambahkan ini
import 'navigation/admin_navigation.dart';
import 'navigation/farmer_navigation.dart';
import 'screens/farmer/dashboard/farmer_dashboard.dart'; // Tambahkan ini
import 'app_user.dart';
import 'core/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting TomaFarm App...');
  
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase initialized successfully!');
    
    runApp(const MyApp());
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TomaFarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      // Cek user yang sudah login
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        print('✅ User already signed in: ${user.email}');
        _currentUser = user;
        
        // Load user data dengan sangat cepat
        final userData = await AppUser.getUserRole(user.uid);
        
        setState(() {
          _userData = userData;
          _isCheckingAuth = false;
        });
      } else {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      print('❌ Error checking auth: $e');
      // Fallback langsung ke home screen
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen hanya saat initial check
    if (_isCheckingAuth) {
      return _buildQuickLoadingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildQuickLoadingScreen();
        }

        // Handle error - langsung fallback ke home screen
        if (snapshot.hasError) {
          print('❌ Auth error: ${snapshot.error}');
          return const HomeScreen();
        }

        // Check user status
        final user = snapshot.data;
        
        if (user == null) {
          print('🚪 No user, redirecting to HomeScreen');
          return const HomeScreen();
        }
        
        print('✅ User authenticated: ${user.email}');
        
        // Gunakan data yang sudah ada atau load baru
        if (_userData != null && _currentUser?.uid == user.uid) {
          print('🎭 Using cached user role: ${_userData!['role']}');
          return _buildNavigationByRole(_userData!);
        }

        // Load user data baru
        return FutureBuilder<Map<String, dynamic>>(
          future: AppUser.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            // Tampilkan loading
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return _buildQuickLoadingScreen();
            }
            
            // Handle error - default ke farmer
            if (roleSnapshot.hasError) {
              print('❌ Role error, default to farmer: ${roleSnapshot.error}');
              final fallbackData = {
                'email': user.email,
                'role': 'farmer',
                'displayName': user.email?.split('@').first ?? 'User',
              };
              return _buildNavigationByRole(fallbackData);
            }
            
            // Gunakan data yang ada
            final userData = roleSnapshot.data!;
            
            print('📊 User data: $userData');
            print('🎭 User role: ${userData['role']}');
            
            return _buildNavigationByRole(userData);
          },
        );
      },
    );
  }

  Widget _buildNavigationByRole(Map<String, dynamic> userData) {
    final isAdmin = userData['role'] == 'admin';
    print('🚀 Navigating to: ${isAdmin ? 'ADMIN' : 'FARMER'} dashboard');
    
    if (isAdmin) {
      return const AdminNavigation();
    } else {
      return const FarmerNavigation();
    }
  }

  Widget _buildQuickLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.agriculture,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TomaFarm',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Menyiapkan aplikasi...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                error.length > 150 ? '${error.substring(0, 150)}...' : error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Lanjutkan ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  error.length > 150 ? '${error.substring(0, 150)}...' : error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}