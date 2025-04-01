import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/auth/app_auth_state.dart'; // Corrected import path

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

    Future<void> _performSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() { _isLoading = true; });
      String? messageToShow; // To store potential feedback message

      try {
        // Use the renamed AppAuthState
        await Provider.of<AppAuthState>(context, listen: false).signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _fullNameController.text.trim(),
        );
         // If signup requires confirmation, an exception is now thrown by signUp method.
         // If signup logs in immediately, navigation happens automatically via listener.
         // If successful without confirmation, we might be navigated away already.
         // We primarily rely on catching the Exception for feedback here.

      } catch (e) {
        messageToShow = e.toString(); // Capture the error/confirmation message
         // Remove "Exception: " prefix if present for cleaner display
        if (messageToShow.startsWith("Exception: ")) {
            messageToShow = messageToShow.substring("Exception: ".length);
        }
      } finally {
        if (mounted) {
           setState(() { _isLoading = false; });
           if (messageToShow != null) { // Only show dialog if there is a message
               // Show a dialog for confirmation message or other errors
               showDialog(
                  context: context,
                  barrierDismissible: false, // User must tap button to close
                  builder: (context) => AlertDialog(
                     // Use null assertion '!' because we checked messageToShow != null
                     title: Text(messageToShow!.contains("check your email") ? 'Signup Almost Done!' : 'Signup Failed'),
                     content: Text(messageToShow), // Display the message itself
                     actions: [
                       TextButton(
                          onPressed: () {
                             Navigator.of(context).pop(); // Close dialog
                             // Use null assertion '!' again - safe due to outer check
                             if (messageToShow!.contains("check your email")) {
                                // Go back to login screen after showing confirmation message
                                 Navigator.of(context).pop(); // This assumes signup screen was pushed onto login
                             }
                          },
                          child: const Text('OK'),
                       ),
                     ],
                  ),
               );
           }
        }
      }
    }
  }
   @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')), // Back button is added automatically
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                   const Icon(Icons.person_add, size: 80, color: Colors.teal),
                   const SizedBox(height: 30),
                   TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                   const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                     keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _performSignup,
                          child: const Text('Sign Up'),
                        ),
                     // Removed the 'Already have an account?' button - user can use AppBar back button
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}