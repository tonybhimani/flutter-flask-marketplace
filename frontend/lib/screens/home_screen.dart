import 'package:flutter/material.dart';
import 'package:marketplace_app/utils/app_helpers.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:marketplace_app/services/listing_service.dart';
import 'package:marketplace_app/screens/auth/login_screen.dart';
import 'package:marketplace_app/screens/create_listing_screen.dart';
import 'package:marketplace_app/screens/listing_detail_screen.dart';
import 'package:marketplace_app/screens/search_screen.dart';
import 'package:marketplace_app/screens/profile_edit_screen.dart';
import 'package:collection/collection.dart'; // Used for firstWhereOrNull extension.

// HomeScreen displays a list of marketplace listings and provides navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService =
      ListingService(); // Service for fetching listings.
  List<dynamic> _listings = []; // List to hold fetched listings.
  bool _isLoading = true; // Indicates if data is currently being loaded.
  String? _errorMessage; // Stores any error message during data fetching.
  Map<String, String> _currentSearchParams =
      {}; // Stores current search parameters.

  @override
  void initState() {
    super.initState();
    _fetchListings(); // Fetch listings when the screen initializes.
  }

  // Fetches listings from the service, optionally with search parameters.
  Future<void> _fetchListings({Map<String, String>? params}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentSearchParams =
          params ?? _currentSearchParams; // Update search params if provided.
    });

    final result = await _listingService.fetchAllListings(
      searchParams: _currentSearchParams,
    );

    if (result['success']) {
      setState(() {
        _listings = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load listings.';
        _isLoading = false;
      });
    }
  }

  // Logs out the current user and navigates to the login screen.
  void _logout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.clearAccessToken(); // Clear stored access token.

    if (mounted) {
      // Navigate to LoginScreen and remove all previous routes.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Navigates to the profile edit screen.
  void _navigateToProfileEdit() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
  }

  // Navigates to the create listing screen and refreshes listings if a new one is created.
  void _navigateToAddListing() async {
    final bool? listingCreated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateListingScreen()),
    );

    if (listingCreated == true) {
      _fetchListings(); // Refresh listings if a new one was added.
    }
  }

  // Navigates to the listing detail screen and refreshes listings if modifications occurred.
  void _navigateToDetail(int listingId) async {
    final bool? listingModified = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListingDetailScreen(listingId: listingId),
      ),
    );

    if (listingModified == true) {
      _fetchListings(); // Refresh listings if the detail screen indicated a change.
    }
  }

  // Navigates to the search screen and applies new search parameters.
  void _navigateToSearch() async {
    final Map<String, String>? searchResults = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialSearchParams: _currentSearchParams,
        ), // Pass current params to search screen.
      ),
    );

    if (searchResults != null) {
      _fetchListings(
        params: searchResults,
      ); // Fetch listings with new search params.
    }
  }

  // Builds a human-readable summary of the current search filters.
  String _buildSearchSummary() {
    if (_currentSearchParams.isEmpty) {
      return '';
    }

    final List<String> parts = [];
    if (_currentSearchParams.containsKey('q') &&
        _currentSearchParams['q']!.isNotEmpty) {
      parts.add('Keywords: "${_currentSearchParams['q']}"');
    }
    if (_currentSearchParams.containsKey('category') &&
        _currentSearchParams['category']!.isNotEmpty) {
      parts.add('Category: "${_currentSearchParams['category']}"');
    }
    if (_currentSearchParams.containsKey('location') &&
        _currentSearchParams['location']!.isNotEmpty) {
      parts.add('Location: "${_currentSearchParams['location']}"');
    }
    if (_currentSearchParams.containsKey('min_price') &&
        _currentSearchParams['min_price']!.isNotEmpty) {
      parts.add('Min Price: \$${_currentSearchParams['min_price']}');
    }
    if (_currentSearchParams.containsKey('max_price') &&
        _currentSearchParams['max_price']!.isNotEmpty) {
      parts.add('Max Price: \$${_currentSearchParams['max_price']}');
    }

    if (parts.isEmpty) {
      return '';
    }
    return 'Filtered by: ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings'),
        actions: [
          // Search button.
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Listings',
            onPressed: _navigateToSearch,
          ),
          // Refresh button.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Listings',
            onPressed: _fetchListings,
          ),
          // Edit Profile button.
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Edit Profile',
            onPressed: _navigateToProfileEdit,
          ),
          // Logout button.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Display search summary if filters are active.
          if (_currentSearchParams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                _buildSearchSummary(),
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Show loading spinner.
                : _errorMessage != null
                ? Center(
                    // Show error message and retry button.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchListings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _listings.isEmpty
                ? Center(
                    // Show message if no listings are found.
                    child: Text(
                      _currentSearchParams.isNotEmpty
                          ? 'No listings found matching your search criteria.'
                          : 'No listings found. Create one!',
                    ),
                  )
                : ListView.builder(
                    // Display listings in a scrollable list.
                    itemCount: _listings.length,
                    itemBuilder: (context, index) {
                      final listing = _listings[index];
                      final List<dynamic> media = listing['media'] ?? [];

                      String? thumbnailUrl;
                      // Find the first image media for the thumbnail.
                      final firstImageMedia = media.firstWhereOrNull(
                        (m) => m['media_type'] == 'image',
                      );
                      if (firstImageMedia != null &&
                          firstImageMedia['url'] != null) {
                        thumbnailUrl = getFullMediaUrl(firstImageMedia['url']);
                      }

                      Widget leadingThumbnail;
                      if (thumbnailUrl != null) {
                        // Display image thumbnail.
                        leadingThumbnail = SizedBox(
                          width: 80,
                          height: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: AspectRatio(
                              aspectRatio: 1 / 1,
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    // Fallback for image loading errors.
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  );
                                },
                                loadingBuilder: // Show progress while image loads.
                                (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Placeholder when no image is available.
                        leadingThumbnail = Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              'No Image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        elevation: 2.0,
                        child: InkWell(
                          onTap: () => _navigateToDetail(
                            listing['id'],
                          ), // Navigate to detail on tap.
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                leadingThumbnail,
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Listing title.
                                      Text(
                                        listing['title'] ?? 'No Title',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      // Listing description (truncated).
                                      Text(
                                        listing['description'] ??
                                            'No Description',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Listing price.
                                      if (listing['price'] != null)
                                        Text(
                                          '\$${listing['price'].toStringAsFixed(2)}',
                                        ),
                                      // Listing category.
                                      Text(
                                        'Category: ${listing['category'] ?? 'N/A'}',
                                      ),
                                      // Listing location.
                                      Text(
                                        'Location: ${listing['location'] ?? 'N/A'}',
                                      ),
                                      // Seller username.
                                      if (listing['author'] != null &&
                                          listing['author']['username'] != null)
                                        Text(
                                          'Seller: ${listing['author']['username']}',
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddListing, // Button to add a new listing.
        tooltip: 'Add New Listing',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Extension to format DateTime to a short date string.
extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/${year.toString().substring(2, 4)}';
  }
}
