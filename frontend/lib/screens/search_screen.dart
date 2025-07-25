import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// SearchScreen allows users to enter various parameters to filter marketplace listings.
// It takes initial search parameters and returns updated parameters upon search or clear.
class SearchScreen extends StatefulWidget {
  final Map<String, String> initialSearchParams;

  const SearchScreen({super.key, required this.initialSearchParams});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for each search input field.
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Focus nodes for each text field to control keyboard focus programmatically.
  final FocusNode _queryFocus = FocusNode();
  final FocusNode _categoryFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _minPriceFocus = FocusNode();
  final FocusNode _maxPriceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with any existing search parameters passed in.
    _queryController.text = widget.initialSearchParams['q'] ?? '';
    _categoryController.text = widget.initialSearchParams['category'] ?? '';
    _locationController.text = widget.initialSearchParams['location'] ?? '';
    _minPriceController.text = widget.initialSearchParams['min_price'] ?? '';
    _maxPriceController.text = widget.initialSearchParams['max_price'] ?? '';
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes to prevent memory leaks.
    _queryController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _queryFocus.dispose();
    _categoryFocus.dispose();
    _locationFocus.dispose();
    _minPriceFocus.dispose();
    _maxPriceFocus.dispose();
    super.dispose();
  }

  // Gathers the entered search parameters and returns them to the previous screen.
  void _performSearch() {
    if (_formKey.currentState!.validate()) {
      // Validate all form fields before proceeding.
      final Map<String, String> searchParams = {};

      // Add non-empty text field values to the search parameters map.
      if (_queryController.text.isNotEmpty) {
        searchParams['q'] = _queryController.text;
      }
      if (_categoryController.text.isNotEmpty) {
        searchParams['category'] = _categoryController.text;
      }
      if (_locationController.text.isNotEmpty) {
        searchParams['location'] = _locationController.text;
      }
      if (_minPriceController.text.isNotEmpty) {
        searchParams['min_price'] = _minPriceController.text;
      }
      if (_maxPriceController.text.isNotEmpty) {
        searchParams['max_price'] = _maxPriceController.text;
      }

      // Pop the screen, returning the collected search parameters.
      Navigator.of(context).pop(searchParams);
    }
  }

  // Clears all search fields and returns an empty map to the previous screen,
  // effectively resetting any active search filters.
  void _clearSearch() {
    _queryController.clear();
    _categoryController.clear();
    _locationController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();

    // Pop the screen, indicating that all search parameters should be cleared.
    Navigator.of(context).pop(<String, String>{});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Search Parameters',
            onPressed: _clearSearch, // Button to clear all search inputs.
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Associate the form key.
          child: ListView(
            // Use ListView for scrollability if the content exceeds screen height.
            children: [
              // Keywords Text Field
              TextFormField(
                controller: _queryController,
                focusNode: _queryFocus,
                decoration: const InputDecoration(
                  labelText: 'Keywords (Title or Description)',
                  hintText: 'e.g., bike, vintage, new',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction
                    .next, // Move to next field on "done" or "next" on keyboard.
                onFieldSubmitted: (value) => FocusScope.of(
                  context,
                ).requestFocus(_categoryFocus), // Move focus to category field.
              ),
              const SizedBox(height: 15),
              // Category Text Field
              TextFormField(
                controller: _categoryController,
                focusNode: _categoryFocus,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., electronics, vehicles, furniture',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (value) => FocusScope.of(
                  context,
                ).requestFocus(_locationFocus), // Move focus to location field.
              ),
              const SizedBox(height: 15),
              // Location Text Field
              TextFormField(
                controller: _locationController,
                focusNode: _locationFocus,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Los Angeles, CA',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (value) =>
                    FocusScope.of(context).requestFocus(
                      _minPriceFocus,
                    ), // Move focus to min price field.
              ),
              const SizedBox(height: 15),
              // Min/Max Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceController,
                      focusNode: _minPriceFocus,
                      keyboardType: TextInputType
                          .number, // Numeric keyboard for price input.
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        hintText: 'e.g., 50',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        // Validate that the input is a valid number if not empty.
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return 'Enter a valid number.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) =>
                          FocusScope.of(context).requestFocus(
                            _maxPriceFocus,
                          ), // Move focus to max price field.
                    ),
                  ),
                  const SizedBox(width: 10), // Spacing between price fields.
                  Expanded(
                    child: TextFormField(
                      controller: _maxPriceController,
                      focusNode: _maxPriceFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        hintText: 'e.g., 500',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        // Validate that the input is a valid number if not empty.
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return 'Enter a valid number.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction
                          .done, // "Done" action for the last field.
                      onFieldSubmitted: (value) =>
                          _performSearch(), // Submit form on "done".
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // Search Button
              ElevatedButton(
                onPressed: _performSearch, // Trigger the search logic.
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Search', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
