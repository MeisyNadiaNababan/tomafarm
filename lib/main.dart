import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'auth/home_screen.dart';
import 'navigation/admin_navigation.dart';
import 'navigation/farmer_navigation.dart';
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
    
    // Test Firebase Auth
    final auth = FirebaseAuth.instance;
    print('🔐 Firebase Auth ready');
    
    // Test Firebase Database
    try {
      final database = FirebaseDatabase.instance;
      print('📊 Database URL: ${database.databaseURL}');
      
      // Test database connection
      final testRef = database.ref('.info/connected');
      testRef.onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        print('📡 Database connection: $connected');
      });
      
      // Test read/write
      await database.ref('test').set({'test': DateTime.now().toString()});
      await database.ref('test').remove();
      print('✅ Database test successful');
      
    } catch (e) {
      print('❌ Database test failed: $e');
    }
    
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
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    print('👤 Current user on init: ${user?.email}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('\n=== AUTH WRAPPER UPDATE ===');
        print('Connection state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        print('Has error: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          print('❌ Auth error: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            print('⏳ Waiting for auth state...');
            return _buildLoadingScreen();
            
          case ConnectionState.active:
          case ConnectionState.done:
            final user = snapshot.data;
            print('🎯 Auth state - User: ${user?.email}');
            
            if (user == null) {
              print('🚪 No user, redirecting to HomeScreen');
              return const HomeScreen();
            }
            
            print('✅ User authenticated: ${user.email}');
            return _buildUserNavigation(user);
        }
      },
    );
  }

  Widget _buildUserNavigation(User user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AppUser.getUserRole(user.uid),
      builder: (context, roleSnapshot) {
        print('\n=== ROLE CHECK ===');
        print('Role connection state: ${roleSnapshot.connectionState}');
        print('Role has data: ${roleSnapshot.hasData}');
        print('Role has error: ${roleSnapshot.hasError}');
        
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Loading user role...');
          return _buildLoadingScreen();
        }
        
        if (roleSnapshot.hasError) {
          print('❌ Role error: ${roleSnapshot.error}');
          // Default ke farmer jika error
          return const FarmerNavigation();
        }
        
        final userData = roleSnapshot.data;
        print('📊 User data: $userData');
        
        final isAdmin = AppUser.isAdmin(userData);
        print('🎭 User role: ${isAdmin ? 'ADMIN' : 'FARMER'}');
        
        return isAdmin ? const AdminNavigation() : const FarmerNavigation();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'TomaFarm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Memuat aplikasi...'),
            const SizedBox(height: 10),
            Text(
              'Firebase: ${Firebase.apps.isNotEmpty ? '✅' : '❌'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                error,
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
                  error,
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