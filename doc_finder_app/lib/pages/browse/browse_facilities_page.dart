import 'package:flutter/material.dart';
import 'package:xyvra_health/services/rating_service.dart';
import 'package:xyvra_health/widgets/star_rating_widget.dart';
import 'package:xyvra_health/pages/find_facility/facility_profile_page.dart';

class BrowseFacilitiesPage extends StatefulWidget {
  const BrowseFacilitiesPage({Key? key}) : super(key: key);

  @override
  _BrowseFacilitiesPageState createState() => _BrowseFacilitiesPageState();
}

class _BrowseFacilitiesPageState extends State<BrowseFacilitiesPage> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _facilities = [];
  List<dynamic> _filteredFacilities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _sortBy = 'rating'; // 'rating', 'name', 'type'

  @override
  void initState() {
    super.initState();
    _loadFacilities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreFacilities();
      }
    }
  }

  Future<void> _loadFacilities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });

      final response = await _ratingService.getFacilitiesWithRatings(page: 1);

      if (response['success'] == true || response['data'] != null) {
        final List<dynamic> facilities = response['data'] as List<dynamic>? ?? [];

        setState(() {
          _facilities = facilities;
          _filteredFacilities = List.from(facilities);
          _isLoading = false;
          _hasMoreData = facilities.length >= 10; // Assuming 10 per page
        });

        _sortFacilities();
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load facilities';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreFacilities() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final response = await _ratingService.getFacilitiesWithRatings(page: _currentPage + 1);

      if (response['success'] == true || response['data'] != null) {
        final List<dynamic> newFacilities = response['data'] as List<dynamic>? ?? [];

        setState(() {
          _facilities.addAll(newFacilities);
          _currentPage++;
          _hasMoreData = newFacilities.length >= 10;
          _isLoadingMore = false;
        });

        _filterAndSortFacilities();
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _filterFacilities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFacilities = List.from(_facilities);
      } else {
        _filteredFacilities = _facilities.where((facility) {
          final name = (facility['facility_name'] ?? '').toString().toLowerCase();
          final type = (facility['facility_type']?['name'] ?? '').toString().toLowerCase();
          final location = (facility['facility_location'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
                 type.contains(searchLower) ||
                 location.contains(searchLower);
        }).toList();
      }
    });
    _sortFacilities();
  }

  void _filterAndSortFacilities() {
    _filterFacilities(_searchController.text);
  }

  void _sortFacilities() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _filteredFacilities.sort((a, b) {
            final aRating = (a['average_rating'] ?? 0.0).toDouble();
            final bRating = (b['average_rating'] ?? 0.0).toDouble();
            return bRating.compareTo(aRating); // Descending
          });
          break;
        case 'name':
          _filteredFacilities.sort((a, b) {
            final aName = a['facility_name'] ?? '';
            final bName = b['facility_name'] ?? '';
            return aName.compareTo(bName); // Ascending
          });
          break;
        case 'type':
          _filteredFacilities.sort((a, b) {
            final aType = a['facility_type']?['name'] ?? '';
            final bType = b['facility_type']?['name'] ?? '';
            return aType.compareTo(bType); // Ascending
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Facilities'),
        backgroundColor: const Color(0xFF008faf),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortFacilities();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _sortBy == 'rating' ? const Color(0xFF008faf) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Rating'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? const Color(0xFF008faf) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'type',
                child: Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: _sortBy == 'type' ? const Color(0xFF008faf) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Type'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          Expanded(
            child: _buildFacilitiesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        onChanged: _filterFacilities,
        decoration: InputDecoration(
          hintText: 'Search facilities by name, type, or location...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterFacilities('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        children: [
          Text(
            '${_filteredFacilities.length} ${_filteredFacilities.length == 1 ? 'facility' : 'facilities'} found',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Sorted by ${_sortBy == 'rating' ? 'Rating' : _sortBy == 'name' ? 'Name' : 'Type'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load facilities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFacilities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredFacilities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No facilities found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredFacilities.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredFacilities.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final facility = _filteredFacilities[index];
        return _buildFacilityCard(facility);
      },
    );
  }

  Widget _buildFacilityCard(dynamic facility) {
    final name = facility['facility_name'] ?? 'Unknown Facility';
    final facilityType = facility['facility_type']?['name'] ?? 'Medical Facility';
    final location = facility['facility_location'] ?? 'Location not specified';
    final averageRating = (facility['average_rating'] ?? 0.0).toDouble();
    final totalRatings = facility['total_ratings'] ?? 0;
    final phone = facility['facility_phone'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacilityProfilePage(
                facilityId: facility['id'],
                facilityData: facility,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF008faf).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_hospital,
                  size: 30,
                  color: const Color(0xFF008faf).withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facilityType,
                      style: TextStyle(
                        color: const Color(0xFF008faf),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (totalRatings > 0) ...[
                      RatingDisplayWidget(
                        averageRating: averageRating,
                        totalRatings: totalRatings,
                        size: 16,
                        compact: true,
                      ),
                    ] else ...[
                      Text(
                        'No ratings yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  if (averageRating > 4.5) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Top Rated',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (phone != null && phone.isNotEmpty) ...[
                        IconButton(
                          icon: Icon(
                            Icons.phone,
                            size: 20,
                            color: Colors.green[600],
                          ),
                          onPressed: () {
                            // TODO: Implement phone call functionality
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
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