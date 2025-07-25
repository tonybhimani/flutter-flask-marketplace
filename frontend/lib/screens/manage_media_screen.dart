import 'package:flutter/material.dart';
import 'package:marketplace_app/utils/app_helpers.dart';
import 'package:marketplace_app/services/listing_service.dart';
import 'package:reorderables/reorderables.dart';

// ManageMediaScreen allows users to reorder and delete media (images/videos)
// associated with a specific listing.
class ManageMediaScreen extends StatefulWidget {
  final String listingId; // The ID of the listing whose media is being managed.
  final List<dynamic>
  initialMedia; // The initial list of media items for the listing.

  const ManageMediaScreen({
    super.key,
    required this.listingId,
    required this.initialMedia,
  });

  @override
  State<ManageMediaScreen> createState() => _ManageMediaScreenState();
}

class _ManageMediaScreenState extends State<ManageMediaScreen> {
  // A local mutable list to hold and manage the media items.
  // It's initialized from `widget.initialMedia` and converted to `Map<String, dynamic>`
  // to ensure mutability and proper type handling.
  late List<Map<String, dynamic>> _mediaItems;
  bool _hasChanges = false;
  final ListingService _listingService = ListingService();
  bool _isProcessingMedia = false;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial media list to allow local modifications.
    _mediaItems = widget.initialMedia
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Callback function for when media items are reordered.
  // It updates the local list and triggers an API call to save the new order.
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _hasChanges = true; // Mark that a change has occurred.
      final item = _mediaItems.removeAt(
        oldIndex,
      ); // Remove the item from its old position.
      _mediaItems.insert(
        newIndex,
        item,
      ); // Insert the item at its new position.
    });

    _updateMediaOrder(); // Call the function to update the order on the backend.
  }

  // Sends an API request to update the order of media items on the server.
  Future<void> _updateMediaOrder() async {
    if (_isProcessingMedia) return; // Prevent multiple concurrent requests.

    setState(() {
      _isProcessingMedia = true; // Set processing state to true.
    });

    // Extract media IDs in their new order.
    final List<int> orderedMediaIds = _mediaItems
        .map((item) => item['id'] as int)
        .toList();

    try {
      final result = await _listingService.updateMediaOrder(
        widget.listingId,
        orderedMediaIds,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media order saved successfully!'),
          ), // Show success message.
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save media order: ${result['message']}',
            ), // Show error message from API.
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving media order: $e')),
      ); // Show generic error message.
    } finally {
      setState(() {
        _isProcessingMedia = false; // Reset processing state.
      });
    }
  }

  // Handles the deletion of a specific media item.
  // Prompts for confirmation before proceeding with deletion.
  void _deleteMedia(int index) async {
    final mediaItemToDelete = _mediaItems[index];
    final int? mediaId = mediaItemToDelete['id'];

    if (mediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Media ID is missing.')),
      );
      return;
    }

    // Show a confirmation dialog before deleting.
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Media?'),
          content: const Text(
            'Are you sure you want to delete this media item?',
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

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting media...')),
      ); // Inform user that deletion is in progress.

      final result = await _listingService.deleteMedia(
        mediaId,
      ); // API call to delete media.

      if (result['success']) {
        setState(() {
          _hasChanges = true; // Mark that a change has occurred.
          _mediaItems.removeAt(index); // Remove the item from the local list.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media removed locally.')),
        ); // Confirm local removal.
        _updateMediaOrder(); // Trigger order update (important if media was in sequence).
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete media: ${result['message']}',
            ), // Show error message from API.
          ),
        );
      }
    }
  }

  // Handles the "Done" action or back button press.
  // Pops the screen, returning the updated media list if changes were made.
  void _onDone() {
    if (_hasChanges) {
      Navigator.of(
        context,
      ).pop(_mediaItems); // Return the updated list if changes were made.
    } else {
      Navigator.of(context).pop(null); // Return null if no changes were made.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent the default back button behavior.
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onDone(); // Call `_onDone` to handle back navigation logic.
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Media'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onDone, // Use `_onDone` for the back button.
          ),
        ),
        body: _isProcessingMedia
            ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator when processing.
            : _mediaItems.isEmpty
            ? const Center(
                // Display message if no media is available.
                child: Text(
                  'No media to manage. Add media on the Listing Detail screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ReorderableWrap(
                    spacing: 8.0, // Horizontal spacing between items.
                    runSpacing: 8.0, // Vertical spacing between rows of items.
                    alignment: WrapAlignment
                        .start, // Align items to the start of the row.
                    onReorder: _onReorder, // Callback for reordering.
                    children: List.generate(_mediaItems.length, (index) {
                      final mediaItem = _mediaItems[index];
                      final mediaType = mediaItem['media_type'] as String;
                      final mediaUrl = getFullMediaUrl(
                        mediaItem['url'] as String,
                      );

                      return SizedBox(
                        key: ValueKey(
                          mediaItem['id'],
                        ), // Unique key required for ReorderableWrap.
                        width: 100,
                        height: 100,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: mediaType == 'image'
                                    ? Image.network(
                                        // Display image.
                                        mediaUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
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
                                        errorBuilder: // Fallback for image loading errors.
                                        (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 50,
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Display a placeholder image for videos.
                                            Image.asset(
                                              'assets/images/video_placeholder.png', // Assuming this asset exists.
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              color: Colors
                                                  .black54, // Darken the placeholder image.
                                              colorBlendMode: BlendMode.darken,
                                            ),
                                            const Icon(
                                              Icons
                                                  .play_circle_fill, // Play icon for videos.
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: GestureDetector(
                                onTap: _isProcessingMedia
                                    ? null // Disable delete button while processing.
                                    : () => _deleteMedia(
                                        index,
                                      ), // Call delete function on tap.
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .red, // Red background for delete button.
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors
                                          .white, // White border for visibility.
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close, // 'X' icon for deletion.
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
      ),
    );
  }
}
