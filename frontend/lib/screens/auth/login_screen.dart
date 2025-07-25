import 'package:flutter/material.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:marketplace_app/screens/auth/register_screen.dart';
import 'package:marketplace_app/screens/home_screen.dart';

// LoginScreen provides a user interface for logging into the application.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation.
  final TextEditingController _usernameController =
      TextEditingController(); // Controller for username input.
  final TextEditingController _passwordController =
      TextEditingController(); // Controller for password input.
  final AuthService _authService =
      AuthService(); // Instance of authentication service.
  String? _errorMessage; // Stores error messages from login attempts.
  bool _isLoading = false; // Controls loading indicator visibility.

  final FocusNode _usernameFocus =
      FocusNode(); // Focus node for username field.
  final FocusNode _passwordFocus =
      FocusNode(); // Focus node for password field.

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Handles the login process.
  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Validate form fields.
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });

      final username = _usernameController.text;
      final password = _passwordController.text;

      // Basic validation for empty fields.
      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter username/email and password.';
          _isLoading = false;
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logging in...')),
      ); // Show loading snackbar.

      // Call the authentication service to log in.
      final result = await _authService.login(
        username: username,
        password: password,
      );

      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(); // Hide loading snackbar.

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (mounted) {
          // Navigate to home screen on successful login, remove all previous routes.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message']; // Display error message.
        });
      }
    }
  }

  // Navigates to the registration screen.
  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Marketplace Demo!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username or email';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (value) {
                    _usernameFocus.unfocus();
                    FocusScope.of(context).requestFocus(
                      _passwordFocus,
                    ); // Move focus to password field.
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true, // Hide password input.
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    _login(); // Attempt login on pressing "done" key.
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator() // Show progress indicator if loading.
                    : ElevatedButton(
                        onPressed: _login, // Trigger login function.
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed:
                      _navigateToRegister, // Navigate to registration screen.
                  child: const Text('Don\'t have an account? Register here.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
