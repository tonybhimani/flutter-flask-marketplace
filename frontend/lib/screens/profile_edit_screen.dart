import 'package:flutter/material.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:marketplace_app/screens/auth/login_screen.dart';

// ProfileEditScreen allows users to view and update their profile information,
// including personal details and password, and offers an option to delete their account.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Text editing controllers for each input field on the profile edit form.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUserData;

  // Focus nodes for each text field to control input focus programmatically.
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneNumberFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the screen initializes.
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes to prevent memory leaks.
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneNumberFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Fetches the current user's profile data from the authentication service.
  // Updates the UI with the fetched data or an error message.
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // Show loading indicator.
      _errorMessage = null; // Clear any previous error messages.
    });

    final result = await _authService
        .fetchCurrentUser(); // Call the service to fetch user data.

    if (mounted) {
      // Check if the widget is still in the tree before calling setState.
      setState(() {
        _isLoading = false; // Hide loading indicator.
      });

      if (result['success']) {
        // If data fetching is successful, populate text controllers with user data.
        _currentUserData = result['user'];
        _usernameController.text = _currentUserData!['username'] ?? '';
        _emailController.text = _currentUserData!['email'] ?? '';
        _firstNameController.text = _currentUserData!['first_name'] ?? '';
        _lastNameController.text = _currentUserData!['last_name'] ?? '';
        _phoneNumberController.text = _currentUserData!['phone_number'] ?? '';
      } else {
        // If fetching fails, display an error message.
        _errorMessage = result['message'] ?? 'Failed to load profile data.';
        // If the session has expired, navigate to the login screen.
        if (result['message'] == 'Session expired. Please log in again.') {
          _navigateToLogin();
        }
      }
    }
  }

  // Navigates to the login screen and removes all previous routes from the stack.
  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) =>
            false, // This predicate ensures all previous routes are removed.
      );
    }
  }

  // Handles the profile update logic.
  // Validates inputs, prepares update data, and calls the authentication service.
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // Validate all form fields.
      setState(() {
        _isLoading = true; // Show loading indicator.
        _errorMessage = null; // Clear previous error messages.
      });

      final Map<String, dynamic> updateData =
          {}; // Map to hold only the changed data.

      // Compare current controller text with initial user data and add to updateData if changed.
      if (_usernameController.text != (_currentUserData!['username'] ?? '')) {
        updateData['username'] = _usernameController.text;
      }
      if (_emailController.text != (_currentUserData!['email'] ?? '')) {
        updateData['email'] = _emailController.text;
      }
      if (_firstNameController.text !=
          (_currentUserData!['first_name'] ?? '')) {
        updateData['first_name'] = _firstNameController.text;
      }
      if (_lastNameController.text != (_currentUserData!['last_name'] ?? '')) {
        updateData['last_name'] = _lastNameController.text;
      }
      if (_phoneNumberController.text !=
          (_currentUserData!['phone_number'] ?? '')) {
        updateData['phone_number'] = _phoneNumberController.text;
      }

      // Handle password change specific validations.
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'New passwords do not match.';
            _isLoading = false;
          });
          return;
        }
        if (_passwordController.text.length < 6) {
          setState(() {
            _errorMessage = 'New password must be at least 6 characters.';
            _isLoading = false;
          });
          return;
        }
        updateData['password'] =
            _passwordController.text; // Add password to update data.
      }

      // If no changes were made and no new password was entered, display a message.
      if (updateData.isEmpty && _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'No changes to save.';
          _isLoading = false;
        });
        return;
      }

      final result = await _authService.updateUser(
        updateData,
      ); // Call the service to update user.

      if (mounted) {
        // Check if the widget is still in the tree.
        setState(() {
          _isLoading = false; // Hide loading indicator.
        });

        if (result['success']) {
          _currentUserData =
              result['user']; // Update local user data with new information.
          _passwordController
              .clear(); // Clear password fields after successful update.
          _confirmPasswordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop(); // Go back to the previous screen.
        } else {
          // Display error message if update fails.
          _errorMessage = result['message'] ?? 'Failed to update profile.';
          if (result['message'] == 'Session expired. Please log in again.') {
            _navigateToLogin();
          }
        }
      }
    }
  }

  // Handles account deletion process.
  // Prompts for confirmation before calling the delete API.
  Future<void> _deleteAccount() async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: const Text(
                'Are you absolutely sure you want to delete your account? '
                'This action is irreversible and will delete all your listings and associated data.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // User cancels deletion.
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ), // Red button for destructive action.
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true); // User confirms deletion.
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed without selection.

    if (confirm) {
      setState(() {
        _isLoading = true; // Show loading indicator.
        _errorMessage = null; // Clear previous error messages.
      });

      final result = await _authService
          .deleteCurrentUser(); // Call the service to delete user.

      if (mounted) {
        // Check if the widget is still in the tree.
        setState(() {
          _isLoading = false; // Hide loading indicator.
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Account deleted successfully!',
              ),
            ),
          );
          _navigateToLogin(); // Navigate to login screen after successful deletion.
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error deleting account.'),
            ),
          );
          _errorMessage = result['message']; // Display error message.
          if (result['message'] == 'Session expired. Please log in again.') {
            _navigateToLogin();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading && _currentUserData == null
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loading indicator if data is being fetched for the first time.
          : _errorMessage != null && _currentUserData == null
          ? Center(
              // Display error message and retry button if initial data fetch failed.
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchUserData, // Retry fetching data.
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              // Scrollable content for the form.
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Associate form key with the Form widget.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Your Account Details',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall, // Headline style.
                    ),
                    const SizedBox(height: 25),
                    // Username Text Field
                    TextFormField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username cannot be empty.';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) =>
                          FocusScope.of(context).requestFocus(
                            _emailFocus,
                          ), // Move focus to next field on submit.
                    ),
                    const SizedBox(height: 15),
                    // Email Text Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email cannot be empty.';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) =>
                          FocusScope.of(context).requestFocus(_firstNameFocus),
                    ),
                    const SizedBox(height: 15),
                    // First Name Text Field
                    TextFormField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) =>
                          FocusScope.of(context).requestFocus(_lastNameFocus),
                    ),
                    const SizedBox(height: 15),
                    // Last Name Text Field
                    TextFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) => FocusScope.of(
                        context,
                      ).requestFocus(_phoneNumberFocus),
                    ),
                    const SizedBox(height: 15),
                    // Phone Number Text Field
                    TextFormField(
                      controller: _phoneNumberController,
                      focusNode: _phoneNumberFocus,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Change Password (leave blank to keep current)',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium, // Subheading style.
                    ),
                    const SizedBox(height: 10),
                    // New Password Text Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: true, // Hide password input.
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        hintText: 'Enter new password if changing',
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) => FocusScope.of(
                        context,
                      ).requestFocus(_confirmPasswordFocus),
                    ),
                    const SizedBox(height: 15),
                    // Confirm New Password Text Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: true, // Hide password input.
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (value) =>
                          _updateProfile(), // Submit form on done.
                    ),
                    const SizedBox(height: 25),
                    // Error Message Display
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Save Changes Button (shows loading indicator when processing)
                    _isLoading && _currentUserData != null
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed:
                                _updateProfile, // Call update profile function.
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Save Changes'),
                          ),
                    const SizedBox(height: 20),
                    // Delete Account Button (red for caution)
                    ElevatedButton(
                      onPressed:
                          _deleteAccount, // Call delete account function.
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red background.
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white, // White text for contrast.
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
