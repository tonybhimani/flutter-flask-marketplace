import 'package:flutter/material.dart';
import 'package:marketplace_app/services/listing_service.dart';
import 'package:marketplace_app/screens/manage_media_screen.dart';
import 'package:intl/intl.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();

  List<dynamic> _currentMedia = [];
  bool _hasMediaChanges = false;
  bool _hasFormChanges = false;

  bool get _anyChangesOccurred {
    return _hasFormChanges || _hasMediaChanges;
  }

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _populateControllers();
    _addChangeListeners();
  }

  void _populateControllers() {
    _titleController.text = widget.listing['title'] ?? '';
    _descriptionController.text = widget.listing['description'] ?? '';

    final num? price = widget.listing['price'];
    _priceController.text = (price != null) ? price.toStringAsFixed(2) : '';

    _categoryController.text = widget.listing['category'] ?? '';
    _locationController.text = widget.listing['location'] ?? '';

    if (widget.listing['valid_until'] != null) {
      _validUntilController.text =
          DateTime.parse(
            widget.listing['valid_until'],
          ).toIso8601String().split('T')[0] +
          'T00:00:00';
    }

    _currentMedia = List<dynamic>.from(widget.listing['media'] ?? []);
  }

  void _addChangeListeners() {
    _titleController.addListener(_setFormChanges);
    _descriptionController.addListener(_setFormChanges);
    _priceController.addListener(_setFormChanges);
    _categoryController.addListener(_setFormChanges);
    _locationController.addListener(_setFormChanges);
    _validUntilController.addListener(_setFormChanges);
  }

  void _setFormChanges() {
    final initialTitle = widget.listing['title'] ?? '';
    final initialDescription = widget.listing['description'] ?? '';
    final initialPrice =
        (widget.listing['price'] as num?)?.toStringAsFixed(2) ?? '';
    final initialCategory = widget.listing['category'] ?? '';
    final initialLocation = widget.listing['location'] ?? '';
    final initialValidUntil = (widget.listing['valid_until'] != null)
        ? DateTime.parse(
                widget.listing['valid_until'],
              ).toIso8601String().split('T')[0] +
              'T00:00:00'
        : '';

    bool currentFormChanges = false;
    if (_titleController.text != initialTitle) currentFormChanges = true;
    if (_descriptionController.text != initialDescription)
      currentFormChanges = true;
    if (_priceController.text != initialPrice) currentFormChanges = true;
    if (_categoryController.text != initialCategory) currentFormChanges = true;
    if (_locationController.text != initialLocation) currentFormChanges = true;
    if (_validUntilController.text != initialValidUntil)
      currentFormChanges = true;

    if (currentFormChanges != _hasFormChanges) {
      setState(() {
        _hasFormChanges = currentFormChanges;
      });
    }
  }

  @override
  void dispose() {
    _removeChangeListeners();
    _disposeControllers();
    super.dispose();
  }

  void _removeChangeListeners() {
    _titleController.removeListener(_setFormChanges);
    _descriptionController.removeListener(_setFormChanges);
    _priceController.removeListener(_setFormChanges);
    _categoryController.removeListener(_setFormChanges);
    _locationController.removeListener(_setFormChanges);
    _validUntilController.removeListener(_setFormChanges);
  }

  void _disposeControllers() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _validUntilController.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntilController.text.isNotEmpty
          ? DateTime.parse(_validUntilController.text)
          : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _validUntilController.text =
            picked.toIso8601String().split('T')[0] + 'T00:00:00';
      });
    }
  }

  Future<void> _manageMedia() async {
    final updatedMedia = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(
        builder: (context) => ManageMediaScreen(
          listingId: widget.listing['id'].toString(),
          initialMedia: List<dynamic>.from(_currentMedia),
        ),
      ),
    );

    if (updatedMedia != null) {
      setState(() {
        _currentMedia = updatedMedia;
        _hasMediaChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media changes applied. Remember to Save Listing!'),
        ),
      );
    }
  }

  void _submitUpdate({bool fromPopScope = false}) async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> updates = {};

    if (_titleController.text != (widget.listing['title'] ?? '')) {
      updates['title'] = _titleController.text;
    }
    if (_descriptionController.text != (widget.listing['description'] ?? '')) {
      updates['description'] = _descriptionController.text;
    }
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice != (widget.listing['price'] as num?)?.toDouble()) {
      updates['price'] = newPrice;
    }
    if (_categoryController.text != (widget.listing['category'] ?? '')) {
      updates['category'] = _categoryController.text;
    }
    if (_locationController.text != (widget.listing['location'] ?? '')) {
      updates['location'] = _locationController.text;
    }

    final String? existingValidUntilFormatted =
        (widget.listing['valid_until'] != null)
        ? DateTime.parse(
                widget.listing['valid_until'],
              ).toIso8601String().split('T')[0] +
              'T00:00:00'
        : '';

    if (_validUntilController.text != existingValidUntilFormatted) {
      updates['valid_until'] = _validUntilController.text.isNotEmpty
          ? _validUntilController.text
          : null;
    }

    setState(() {
      _hasFormChanges = updates.isNotEmpty;
    });

    if (updates.isEmpty && !_hasMediaChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save.')));
      setState(() {
        _isLoading = false;
      });
      if (fromPopScope) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    bool formUpdateSuccess = true;
    if (updates.isNotEmpty) {
      final result = await _listingService.updateListing(
        widget.listing['id'],
        updates,
      );

      if (!result['success']) {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to update listing.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $_errorMessage')));
        formUpdateSuccess = false;
      }
    }

    setState(() {
      _isLoading = false;

      if (formUpdateSuccess) {
        _hasFormChanges = false;
      }
      _hasMediaChanges = false;
    });

    if (formUpdateSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_anyChangesOccurred) {
          final bool? shouldSave = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Do you want to save them before leaving?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Discard',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Save'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );

          if (shouldSave == true) {
            _submitUpdate(fromPopScope: true);
          } else if (shouldSave == false) {
            Navigator.of(context).pop(_hasMediaChanges);
          }
        } else {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Listing'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.photo_library),
              tooltip: 'Manage Photos/Videos',
              onPressed: _manageMedia,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
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
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _validUntilController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          labelText: 'Valid Until (optional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () => _submitUpdate(fromPopScope: false),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
