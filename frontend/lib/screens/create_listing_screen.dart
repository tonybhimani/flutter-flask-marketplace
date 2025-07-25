import 'package:flutter/material.dart';
import 'package:marketplace_app/services/listing_service.dart';
import 'package:intl/intl.dart';

// CreateListingScreen provides the UI for users to create a new marketplace listing.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation.
  final ListingService _listingService =
      ListingService(); // Service for interacting with listing API.

  // Text editing controllers for all input fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();

  bool _isLoading = false; // Controls loading indicator visibility.
  String? _errorMessage; // Stores error messages from API calls.

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks.
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  // Shows a date picker and updates the validUntil field.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
        const Duration(days: 30),
      ), // Default to 30 days from now.
      firstDate: DateTime.now(), // Cannot pick a date in the past.
      lastDate: DateTime(2101), // Arbitrary future limit.
    );
    if (picked != null) {
      // Format the picked date to ISO 8601 string for API, without time.
      _validUntilController.text =
          picked.toIso8601String().split('T')[0] + 'T00:00:00';
    }
  }

  // Submits the new listing data to the backend.
  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      // Validate form fields.
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Extract values from controllers.
      final title = _titleController.text;
      final description = _descriptionController.text;
      final price = double.tryParse(
        _priceController.text,
      ); // Parse price as double.
      final category = _categoryController.text.isNotEmpty
          ? _categoryController.text
          : null;
      final location = _locationController.text.isNotEmpty
          ? _locationController.text
          : null;
      final validUntil = _validUntilController.text.isNotEmpty
          ? _validUntilController.text
          : null;

      // Call the listing service to create the listing.
      final result = await _listingService.createListing(
        title: title,
        description: description,
        price: price,
        category: category,
        location: location,
        validUntil: validUntil,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );
        Navigator.of(context).pop(true); // Pop with 'true' to indicate success.
      } else {
        setState(() {
          _errorMessage =
              result['message'] ??
              'Failed to create listing.'; // Display error message.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_errorMessage}')),
        ); // Show error snackbar.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Listing')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loading indicator when submitting.
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  // Use ListView for scrollable form.
                  children: [
                    // Title input field.
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // Description input field.
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3, // Allow multiple lines for description.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // Price input field (optional, numeric).
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number, // Numeric keyboard.
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return 'Please enter a valid number for price.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // Category input field (optional).
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Location input field (optional).
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Valid Until date picker field (optional).
                    TextFormField(
                      controller: _validUntilController,
                      readOnly: true, // Make field read-only.
                      onTap: () =>
                          _selectDate(context), // Open date picker on tap.
                      decoration: const InputDecoration(
                        labelText: 'Valid Until (optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                        ), // Calendar icon.
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display error message if present.
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Submit button.
                    ElevatedButton(
                      onPressed: _submitListing, // Trigger listing submission.
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Create Listing',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
