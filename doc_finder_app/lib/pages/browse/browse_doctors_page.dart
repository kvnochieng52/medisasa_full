import 'package:flutter/material.dart';
import 'package:xyvra_health/services/rating_service.dart';
import 'package:xyvra_health/widgets/star_rating_widget.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_profile_page.dart';

class BrowseDoctorsPage extends StatefulWidget {
  const BrowseDoctorsPage({Key? key}) : super(key: key);

  @override
  _BrowseDoctorsPageState createState() => _BrowseDoctorsPageState();
}

class _BrowseDoctorsPageState extends State<BrowseDoctorsPage> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _doctors = [];
  List<dynamic> _filteredDoctors = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _sortBy = 'rating'; // 'rating', 'name', 'experience'

  @override
  void initState() {
    super.initState();
    _loadDoctors();
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
        _loadMoreDoctors();
      }
    }
  }

  Future<void> _loadDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });

      final response = await _ratingService.getDoctorsWithRatings(page: 1);

      if (response['success'] == true || response['data'] != null) {
        final List<dynamic> doctors = response['data'] as List<dynamic>? ?? [];

        setState(() {
          _doctors = doctors;
          _filteredDoctors = List.from(doctors);
          _isLoading = false;
          _hasMoreData = doctors.length >= 10; // Assuming 10 per page
        });

        _sortDoctors();
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load doctors';
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

  Future<void> _loadMoreDoctors() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final response = await _ratingService.getDoctorsWithRatings(page: _currentPage + 1);

      if (response['success'] == true || response['data'] != null) {
        final List<dynamic> newDoctors = response['data'] as List<dynamic>? ?? [];

        setState(() {
          _doctors.addAll(newDoctors);
          _currentPage++;
          _hasMoreData = newDoctors.length >= 10;
          _isLoadingMore = false;
        });

        _filterAndSortDoctors();
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

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = List.from(_doctors);
      } else {
        _filteredDoctors = _doctors.where((doctor) {
          final name = (doctor['name'] ?? '').toString().toLowerCase();
          final specialization = (doctor['specialization'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || specialization.contains(searchLower);
        }).toList();
      }
    });
    _sortDoctors();
  }

  void _filterAndSortDoctors() {
    _filterDoctors(_searchController.text);
  }

  void _sortDoctors() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _filteredDoctors.sort((a, b) {
            final aRating = (a['average_rating'] ?? 0.0).toDouble();
            final bRating = (b['average_rating'] ?? 0.0).toDouble();
            return bRating.compareTo(aRating); // Descending
          });
          break;
        case 'name':
          _filteredDoctors.sort((a, b) {
            final aName = a['name'] ?? '';
            final bName = b['name'] ?? '';
            return aName.compareTo(bName); // Ascending
          });
          break;
        case 'experience':
          _filteredDoctors.sort((a, b) {
            final aExp = a['experience_years'] ?? 0;
            final bExp = b['experience_years'] ?? 0;
            return bExp.compareTo(aExp); // Descending
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Doctors'),
        backgroundColor: const Color(0xFF008faf),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortDoctors();
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
                value: 'experience',
                child: Row(
                  children: [
                    Icon(
                      Icons.work,
                      color: _sortBy == 'experience' ? const Color(0xFF008faf) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Experience'),
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
            child: _buildDoctorsList(),
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
        onChanged: _filterDoctors,
        decoration: InputDecoration(
          hintText: 'Search doctors by name or specialty...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterDoctors('');
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
            '${_filteredDoctors.length} ${_filteredDoctors.length == 1 ? 'doctor' : 'doctors'} found',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Sorted by ${_sortBy == 'rating' ? 'Rating' : _sortBy == 'name' ? 'Name' : 'Experience'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
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
                'Failed to load doctors',
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
                onPressed: _loadDoctors,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredDoctors.isEmpty) {
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
                'No doctors found',
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
      itemCount: _filteredDoctors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredDoctors.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final doctor = _filteredDoctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(dynamic doctor) {
    final name = doctor['name'] ?? 'Unknown Doctor';
    final specialization = doctor['specialization'] ?? 'General Practice';
    final experienceYears = doctor['experience_years'] ?? 0;
    final profileImage = doctor['profile_image'] as String?;
    final averageRating = (doctor['average_rating'] ?? 0.0).toDouble();
    final totalRatings = doctor['total_ratings'] ?? 0;

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
              builder: (context) => DoctorProfilePage(
                doctorId: doctor['id'],
                doctorData: doctor,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF008faf).withOpacity(0.1),
                backgroundImage: profileImage != null && profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage == null || profileImage.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: const Color(0xFF008faf).withOpacity(0.7),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialization,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$experienceYears years experience',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
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