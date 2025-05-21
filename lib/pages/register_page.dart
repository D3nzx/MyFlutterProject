import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late final NavigatorState _navigator;
  late final ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        _showSnackBar(
          message: 'Account created! Redirecting to login...',
          color: Colors.green,
        );
        _emailController.clear();
        _passwordController.clear();
        _navigateWithFade(const LoginPage());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showAuthError(e.code);
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        if (mounted) {
          _showSnackBar(
            message: 'Account created! Redirecting to login...',
            color: Colors.green,
          );
          _emailController.clear();
          _passwordController.clear();
          _navigateWithFade(const LoginPage());
        }
      } else if (mounted) {
        _showSnackBar(
          message: 'Error: ${e.toString()}',
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthError(String errorCode) {
    final errorMessage = switch (errorCode) {
      'email-already-in-use' => 'Email already in use',
      'invalid-email' => 'Invalid email format',
      'weak-password' => 'Password should be at least 6 characters',
      'operation-not-allowed' => 'Registration is not enabled',
      _ => 'Registration failed (code: $errorCode)',
    };

    _showSnackBar(
      message: errorMessage,
      color: const Color(0xFF1DA1F2),
    );
  }

  void _showSnackBar({required String message, required Color color}) {
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  void _navigateWithFade(Widget page) {
    _navigator.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF15202B),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo and name
                  const Column(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 80,
                        color: Color(0xFF1DA1F2),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Friendify",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Register Card
                  Card(
                    color: const Color(0xFF192734),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                labelText: "Email",
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF1DA1F2)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                errorStyle: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your password';
                                if (value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                labelText: "Password",
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF1DA1F2)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                errorStyle: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1DA1F2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  "REGISTER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _navigateWithFade(const LoginPage()),
                              child: const Text(
                                "Already have an account? Login",
                                style: TextStyle(
                                  color: Color(0xFF1DA1F2),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}