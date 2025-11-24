import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_user.dart';
import 'signup_screen.dart';
import '../navigation/farmer_navigation.dart'; // Tambahkan import ini
import '../navigation/admin_navigation.dart'; // Tambahkan import ini

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();

  bool loading = false;
  bool hidePass = true;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      if (cred.user != null) {
        // Preload user data
        await AppUser.preloadUser(cred.user!.uid);
        
        // Get user role untuk menentukan navigasi
        final userData = await AppUser.getUserRole(cred.user!.uid);
        
        if (mounted) {
          // Tampilkan snackbar sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login berhasil"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigasi ke halaman yang sesuai berdasarkan role
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => userData['role'] == 'admin' 
                  ? const AdminNavigation() 
                  : const FarmerNavigation(),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Terjadi kesalahan";

      switch (e.code) {
        case "user-not-found":
          msg = "Email tidak ditemukan";
          break;
        case "wrong-password":
          msg = "Password salah";
          break;
        case "invalid-email":
          msg = "Format email salah";
          break;
        case "network-request-failed":
          msg = "Koneksi bermasalah";
          break;
        case "too-many-requests":
          msg = "Terlalu banyak percobaan. Coba lagi nanti";
          break;
        default:
          msg = "Login gagal: ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ICON
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.agriculture,
                    size: 60, color: Colors.green),
              ),

              const SizedBox(height: 20),

              Text(
                "TomaFarm",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || !v.contains("@") ? "Email tidak valid" : null,
              ),
              const SizedBox(height: 20),

              // PASSWORD
              TextFormField(
                controller: _pass,
                obscureText: hidePass,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        hidePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => hidePass = !hidePass),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.length < 6 ? "Minimal 6 karakter" : null,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Masuk",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: loading 
                    ? null 
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                child: const Text("Belum punya akun? Daftar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }
}