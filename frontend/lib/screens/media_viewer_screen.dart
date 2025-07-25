import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:marketplace_app/utils/app_helpers.dart';
import 'package:marketplace_app/services/listing_service.dart';

// MediaViewerScreen displays a full-screen gallery of media items (images and videos).
// It allows users to swipe through media and provides an option to delete media for owners.
class MediaViewerScreen extends StatefulWidget {
  final List<dynamic> mediaItems; // The list of media items to display.
  final int initialIndex; // The index of the media item to show first.

  const MediaViewerScreen({
    super.key,
    required this.mediaItems,
    this.initialIndex =
        0, // Default to the first item if no initial index is provided.
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoadingVideo = false;
  String? _videoErrorMessage;
  final ListingService _listingService = ListingService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Initialize current index.
    _pageController = PageController(
      initialPage: _currentIndex,
    ); // Set initial page for the PageView.
    _initializeMedia(
      _currentIndex,
    ); // Initialize the media at the initial index.
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose the page controller.
    _videoPlayerController?.dispose(); // Dispose video player controller.
    _chewieController?.dispose(); // Dispose Chewie controller.
    super.dispose();
  }

  // Initializes the media item at the given index.
  // This includes setting up video controllers if the media is a video.
  Future<void> _initializeMedia(int index) async {
    // Dispose previous video controllers if they exist.
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;

    if (index < 0 || index >= widget.mediaItems.length) {
      return; // Prevent out-of-bounds access.
    }

    final mediaItem = widget.mediaItems[index];
    final mediaType = mediaItem['media_type'] as String;
    final mediaUrl = getFullMediaUrl(mediaItem['url'] as String);

    if (mediaType == 'video') {
      setState(() {
        _isLoadingVideo = true; // Show loading indicator for video.
        _videoErrorMessage = null; // Clear previous video error.
      });
      try {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        );
        await _videoPlayerController!
            .initialize(); // Initialize the video player.
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true, // Auto-play video.
          looping: false, // Don't loop by default.
          aspectRatio: _videoPlayerController!
              .value
              .aspectRatio, // Maintain aspect ratio.
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage ??
                    'Error loading video.', // Display video loading error.
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      } catch (e) {
        _videoErrorMessage =
            'Failed to load video: $e'; // Set specific video loading error.
        print('Video loading error: $e');
      } finally {
        setState(() {
          _isLoadingVideo = false; // Hide video loading indicator.
        });
      }
    }
    setState(
      () {},
    ); // Trigger rebuild to update UI based on video initialization.
  }

  // Handles the deletion of the currently viewed media item.
  Future<void> _deleteCurrentMedia() async {
    if (_isLoadingVideo ||
        _videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized) {
      // Pause video playback before showing dialog.
      _videoPlayerController?.pause();
    }

    final mediaItemToDelete = widget.mediaItems[_currentIndex];
    final int? mediaId = mediaItemToDelete['id'];

    if (mediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Media ID is missing.')),
      );
      return;
    }

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
              onPressed: () {
                Navigator.of(context).pop(false);
                // Resume video playback if user cancels deletion and it was playing
                if (_videoPlayerController != null &&
                    _videoPlayerController!.value.isInitialized &&
                    _chewieController!.isPlaying) {
                  _videoPlayerController?.play();
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleting media...')));

      final result = await _listingService.deleteMedia(
        mediaId,
      ); // API call to delete media.

      if (result['success']) {
        // Create a mutable copy of the media items list.
        final List<dynamic> updatedMediaItems = List.from(widget.mediaItems);
        updatedMediaItems.removeAt(_currentIndex); // Remove the deleted item.

        // If there are no more media items, pop the screen.
        if (updatedMediaItems.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop(true); // Indicate a change happened.
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Last media item deleted.')),
          );
        } else {
          // If media remains, update the view.
          setState(() {
            // Update the PageView's current index to ensure it points to a valid item.
            // If the last item was deleted, go to the new last item, otherwise stay at current or next.
            _currentIndex = _currentIndex.clamp(
              0,
              updatedMediaItems.length - 1,
            );
            _pageController = PageController(
              initialPage: _currentIndex,
            ); // Reinitialize page controller.
            _initializeMedia(
              _currentIndex,
            ); // Initialize the new current media.
            // Pop with the updated list so the previous screen can refresh.
            Navigator.of(context).pop(updatedMediaItems);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Media deleted successfully!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete media: ${result['message']}'),
          ),
        );
        // Resume video playback if deletion failed and it was playing before.
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized &&
            _chewieController!.isPlaying) {
          _videoPlayerController?.play();
        }
      }
    } else {
      // If the user cancelled, ensure video resumes playback if it was paused for the dialog
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized &&
          _chewieController!.isPlaying) {
        _videoPlayerController?.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Full screen black background for media viewing.
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White icons for contrast.
        actions: [
          // Only show delete option if there are media items.
          if (widget.mediaItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCurrentMedia, // Delete current media item.
              tooltip: 'Delete Media',
            ),
        ],
      ),
      body: widget.mediaItems.isEmpty
          ? const Center(
              child: Text(
                'No media to display.', // Message if no media items.
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index; // Update current index on page change.
                });
                _initializeMedia(index); // Initialize media for the new page.
              },
              itemBuilder: (context, index) {
                final mediaItem = widget.mediaItems[index];
                final mediaType = mediaItem['media_type'] as String;
                final mediaUrl = getFullMediaUrl(mediaItem['url'] as String);

                return Center(
                  child: Builder(
                    builder: (context) {
                      if (_isLoadingVideo && mediaType == 'video') {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _videoErrorMessage ??
                                  'Loading video...', // Show video loading message or error.
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      } else if (_videoErrorMessage != null &&
                          mediaType == 'video') {
                        return Center(
                          child: Text(
                            _videoErrorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (mediaType == 'image') {
                        return InteractiveViewer(
                          // Allows zooming and panning for images.
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit
                                .contain, // Contain the image within the screen.
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 100,
                              );
                            },
                          ),
                        );
                      } else if (mediaType == 'video' &&
                          _chewieController != null &&
                          _chewieController!
                              .videoPlayerController
                              .value
                              .isInitialized) {
                        return Chewie(
                          controller:
                              _chewieController!, // Display video using Chewie.
                        );
                      } else if (mediaType == 'video' &&
                          !_isLoadingVideo &&
                          _videoErrorMessage == null) {
                        // This case can occur if _initializeMedia hasn't completed or encountered an unexpected state.
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      return const Center(
                        child: Text(
                          'Unsupported media type or error.', // Fallback for unhandled cases.
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
