import 'package:flutter/material.dart';
import 'package:marketplace_app/utils/app_helpers.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:marketplace_app/services/listing_service.dart';
import 'package:marketplace_app/screens/edit_listing_screen.dart';
import 'package:marketplace_app/screens/media_viewer_screen.dart';
import 'package:image_picker/image_picker.dart'; // Package for picking images/videos from gallery/camera.
import 'package:intl/intl.dart'; // Package for date and time formatting.
import 'dart:convert'; // For JSON decoding.

// ListingDetailScreen displays the detailed information of a single listing.
// It allows the owner to edit, delete, or add media to the listing.
class ListingDetailScreen extends StatefulWidget {
  final int listingId; // The ID of the listing to display.

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _listing;
  bool _hasChanges = false;
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId;

  final ScrollController _mediaScrollController = ScrollController();

  bool _isUploadingMedia = false;
  String? _mediaUploadErrorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchListingDetails(); // Fetch listing details when the screen initializes.
  }

  @override
  void dispose() {
    _mediaScrollController
        .dispose(); // Dispose the scroll controller to prevent memory leaks.
    super.dispose();
  }

  // Fetches the details of the listing using its ID.
  Future<void> _fetchListingDetails() async {
    setState(() {
      _isLoading = true; // Set loading state to true.
      _errorMessage = null; // Clear any previous error messages.
    });

    await _getCurrentUserId(); // Get the current user's ID to check ownership.

    final result = await _listingService.fetchListingById(
      widget.listingId,
    ); // API call to fetch listing.

    if (result['success']) {
      setState(() {
        _listing = result['data']; // Update listing data.
        _isLoading = false; // Set loading state to false.
      });
    } else {
      setState(() {
        _errorMessage =
            result['message'] ??
            'Failed to load listing details.'; // Set error message.
        _isLoading = false; // Set loading state to false.
      });
    }
  }

  // Decodes the JWT token to extract and set the current user's ID.
  Future<void> _getCurrentUserId() async {
    final String? token = await _authService
        .getAccessToken(); // Retrieve access token.
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          // Decode the payload part of the JWT.
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          setState(() {
            _currentUserId = int.tryParse(
              payload['sub'].toString(),
            ); // Parse user ID from payload.
          });
        }
      } catch (e) {
        print(
          'Error decoding JWT payload or parsing user ID: $e',
        ); // Log any decoding errors.
      }
    }
  }

  // Navigates to the EditListingScreen and refreshes details if the listing was edited.
  void _navigateToEditListing() async {
    if (_listing == null)
      return; // Prevent navigation if listing data isn't loaded.

    final bool? listingEdited = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EditListingScreen(listing: _listing!), // Pass current listing data.
      ),
    );

    if (listingEdited == true) {
      await _fetchListingDetails(); // Re-fetch details to show updates.
      if (mounted) {
        Navigator.of(context).pop(
          true,
        ); // Pop with 'true' to indicate a change to the previous screen.
      }
    }
  }

  // Handles the deletion of the current listing after user confirmation.
  Future<void> _deleteListing() async {
    if (_listing == null)
      return; // Prevent deletion if listing data isn't loaded.

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${_listing!['title']}"?', // Confirmation message.
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Cancel button.
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Confirm delete button.
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true; // Set loading state.
        _errorMessage = null; // Clear error message.
      });

      final result = await _listingService.deleteListing(
        widget.listingId,
      ); // API call to delete listing.

      if (result['success']) {
        if (mounted) {
          Navigator.of(context).pop(
            true,
          ); // Pop with 'true' to indicate deletion to the previous screen.
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully!'),
          ), // Show success message.
        );
      } else {
        setState(() {
          _errorMessage =
              result['message'] ??
              'Failed to delete listing.'; // Set error message.
          _isLoading = false; // End loading state.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_errorMessage}')),
        ); // Show error message.
      }
    }
  }

  // Checks if the current user is the owner of the displayed listing.
  bool _isOwner() {
    if (_listing == null ||
        _currentUserId == null ||
        _listing!['author'] == null ||
        _listing!['author']['id'] == null) {
      return false; // Not the owner if data is incomplete.
    }

    final bool ownerMatch =
        _listing!['author']['id'] ==
        _currentUserId; // Compare user ID with author ID.

    return ownerMatch;
  }

  // Allows the user to pick images/videos and uploads them for the current listing.
  Future<void> _pickAndUploadMedia() async {
    if (_listing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot upload media: Listing not loaded.'),
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker
          .pickMultipleMedia(); // Open media picker.

      if (pickedFiles.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No media selected.')));
        return;
      }

      setState(() {
        _hasChanges = true; // Mark that changes occurred.
        _isUploadingMedia = true; // Set uploading state.
        _mediaUploadErrorMessage = null; // Clear previous upload errors.
      });

      final result = await _listingService.uploadMediaForListing(
        _listing!['id'],
        pickedFiles,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media uploaded successfully!'),
          ), // Show success message.
        );
        _fetchListingDetails(); // Re-fetch details to show new media.
      } else {
        setState(() {
          _mediaUploadErrorMessage =
              result['message'] ??
              'Failed to upload media.'; // Set upload error message.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload Error: $_mediaUploadErrorMessage'),
          ), // Show upload error.
        );
      }
    } catch (e) {
      setState(() {
        _mediaUploadErrorMessage =
            'Error selecting or uploading media: $e'; // Catch and set general errors.
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload Error: $_mediaUploadErrorMessage')),
      );
    } finally {
      setState(() {
        _isUploadingMedia = false; // End uploading state.
      });
    }
  }

  // Handles the back navigation, passing true if changes were made.
  void _onDone() {
    if (_hasChanges) {
      Navigator.of(context).pop(true); // Pop with 'true' if there were changes.
    } else {
      Navigator.of(context).pop(null); // Pop with 'null' if no changes.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent popping directly without calling _onDone.
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onDone(); // Call _onDone when back button is pressed.
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Listing Details'),
          actions: [
            // Display action buttons only if loaded and current user is owner.
            if (!_isLoading && _listing != null && _isOwner()) ...[
              IconButton(
                icon: _isUploadingMedia
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      ) // Show loading indicator during upload.
                    : const Icon(Icons.add_photo_alternate), // Add media icon.
                tooltip: 'Add Photos/Videos',
                onPressed: _isUploadingMedia
                    ? null
                    : _pickAndUploadMedia, // Disable button during upload.
              ),
              IconButton(
                icon: const Icon(Icons.edit), // Edit listing icon.
                tooltip: 'Edit Listing',
                onPressed: _navigateToEditListing,
              ),
              IconButton(
                icon: const Icon(Icons.delete), // Delete listing icon.
                tooltip: 'Delete Listing',
                onPressed: _deleteListing,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator.
            : _errorMessage != null
            ? Center(
                // Show error message and retry button.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          _fetchListingDetails, // Retry fetching details.
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _listing == null
            ? const Center(
                child: Text('Listing not found.'),
              ) // Message if listing data is null after loading.
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _listing!['title'] ??
                          'No Title', // Display listing title.
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Price: \$${_listing!['price']?.toStringAsFixed(2) ?? 'N/A'}', // Display price.
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Description: ${_listing!['description'] ?? 'No Description'}', // Display description.
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Location: ${_listing!['location'] ?? 'N/A'}',
                    ), // Display location.
                    Text(
                      'Category: ${_listing!['category'] ?? 'N/A'}',
                    ), // Display category.
                    if (_listing!['author'] != null &&
                        _listing!['author']['username'] != null)
                      Text(
                        'Seller: ${_listing!['author']['username']}',
                      ), // Display seller username.
                    if (_listing!['created_at'] != null)
                      Text(
                        'Posted: ${DateFormat.yMd().add_jm().format(DateTime.parse(_listing!['created_at']))}', // Display creation date.
                      ),
                    if (_listing!['valid_until'] != null)
                      Text(
                        'Valid Until: ${DateFormat.yMd().format(DateTime.parse(_listing!['valid_until']))}', // Display validity date.
                      ),
                    const SizedBox(height: 20),

                    // Display media section if media exists.
                    if (_listing!['media'] != null &&
                        _listing!['media'].isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Media:',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              return SizedBox(
                                height:
                                    200, // Fixed height for horizontal media list.
                                width: constraints.maxWidth,
                                child: Scrollbar(
                                  controller: _mediaScrollController,
                                  thumbVisibility: true,
                                  thickness: 10,
                                  trackVisibility: true,
                                  child: ListView.builder(
                                    controller: _mediaScrollController,
                                    scrollDirection: Axis
                                        .horizontal, // Horizontal scroll for media.
                                    itemCount: _listing!['media'].length,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(), // Always allow scrolling.
                                    itemBuilder: (context, index) {
                                      final mediaItem =
                                          _listing!['media'][index];
                                      final mediaUrl =
                                          mediaItem['url'] as String;
                                      final mediaType =
                                          mediaItem['media_type'] as String;

                                      String fullMediaUrl = getFullMediaUrl(
                                        mediaUrl,
                                      );

                                      return GestureDetector(
                                        onTap: () {
                                          // Navigate to MediaViewerScreen on tap.
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MediaViewerScreen(
                                                    mediaItems:
                                                        _listing!['media'],
                                                    initialIndex: index,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            child: mediaType == 'image'
                                                ? Image.network(
                                                    // Display image.
                                                    fullMediaUrl,
                                                    width: 150,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return Center(
                                                            child: CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                          );
                                                        },
                                                    errorBuilder: // Fallback for image load errors.
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Container(
                                                            width: 150,
                                                            height: 200,
                                                            color: Colors
                                                                .grey[300],
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          );
                                                        },
                                                  )
                                                : Container(
                                                    // Placeholder for video.
                                                    width: 150,
                                                    height: 200,
                                                    color: Colors.blueGrey[700],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.videocam,
                                                        color: Colors.white,
                                                        size: 50,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
