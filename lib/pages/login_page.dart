import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late final NavigatorState _navigator;
  late final ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Always navigate to home if we get here (works around PigeonUserDetails error)
        if (mounted) {
          _scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Login successful! Redirecting...')),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          _navigator.pushReplacementNamed('/home');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          _showAuthError(e.code);
        }
      }
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        // Special handling for the known decoding error
        if (mounted) {
          _scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Login successful! Redirecting...')),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          _navigator.pushReplacementNamed('/home');
        }
      } else if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAuthError(String errorCode) {
    final errorMessage = switch (errorCode) {
      'user-not-found' || 'wrong-password' => 'Invalid email or password',
      'invalid-email' => 'Invalid email format',
      'user-disabled' => 'This account has been disabled',
      'network-request-failed' => 'Network error, please check your connection',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'operation-not-allowed' => 'Email/password sign-in is not enabled',
      _ => 'Authentication failed (code: $errorCode)',
    };

    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}