import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/auth/app_auth_state.dart';
import 'package:ride_share_app/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _performLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true );
      try {
        await Provider.of<AppAuthState>(context, listen: false).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      height: 200, // Adjusted height to better match the image
                      child: Image.asset(
                        'assets/images/login_banner.png',
                        fit: BoxFit.contain,
                         errorBuilder: (context, error, stackTrace) {
                           return const Center(child: Text('Image not found', style: TextStyle(color: Colors.red)));
                         },
                      ),
                    ),
                    const SizedBox(height: 30), // Adjusted spacing

                    // --- Email Field with SizedBox ---
                    SizedBox(
                      width: 350, // Adjust this value to your desired width
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12), // Adjusted spacing

                    // --- Password Field with SizedBox ---
                    SizedBox(
                      width: 100, // Adjust this value to your desired width (can be the same as email)
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20), // Adjusted spacing

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox( // Wrap the button in SizedBox to control its width
                            width: 350, // Match the width of the text fields
                            child: ElevatedButton(
                              onPressed: _performLogin,
                              child: const Text('Login'),
                            ),
                          ),
                    const SizedBox(height: 10), // Adjusted spacing

                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: const Text('Don\'t have an account? Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}