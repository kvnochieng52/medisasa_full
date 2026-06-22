import 'package:flutter/material.dart';
import 'package:xyvra_health/widgets/star_rating_widget.dart';
import 'package:xyvra_health/services/rating_service.dart';

class RatingDisplayWidget extends StatefulWidget {
  final String rateableType; // 'doctor' or 'facility'
  final int rateableId;
  final bool showAddRatingButton;
  final String? rateableName;
  final VoidCallback? onAddRating;

  const RatingDisplayWidget({
    Key? key,
    required this.rateableType,
    required this.rateableId,
    this.showAddRatingButton = false,
    this.rateableName,
    this.onAddRating,
  }) : super(key: key);

  @override
  _RatingDisplayWidgetState createState() => _RatingDisplayWidgetState();
}

class _RatingDisplayWidgetState extends State<RatingDisplayWidget> {
  final RatingService _ratingService = RatingService();
  Map<String, dynamic>? _ratingsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _ratingService.getRatings(
        type: widget.rateableType,
        id: widget.rateableId,
      );

      if (response['success'] == true) {
        setState(() {
          _ratingsData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load ratings';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load ratings',
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadRatings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ratingsData == null) {
      return const SizedBox.shrink();
    }

    final statistics = _ratingsData!['statistics'] as Map<String, dynamic>? ?? {};
    final ratings = _ratingsData!['ratings'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingsHeader(statistics),
        const SizedBox(height: 16),

        if (statistics['total_ratings'] > 0) ...[
          _buildStatistics(statistics),
          const SizedBox(height: 24),

          if (widget.rateableType == 'doctor' &&
              statistics.containsKey('detailed_averages') &&
              statistics['detailed_averages'] != null) ...[
            _buildDetailedRatings(statistics['detailed_averages']),
            const SizedBox(height: 24),
          ],

          _buildRatingsList(ratings),
        ] else ...[
          _buildNoRatingsMessage(),
        ],
      ],
    );
  }

  Widget _buildRatingsHeader(Map<String, dynamic> statistics) {
    final averageRating = (statistics['average_rating'] ?? 0.0).toDouble();
    final totalRatings = statistics['total_ratings'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ratings & Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (totalRatings > 0) ...[
                    Row(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StarRatingWidget(
                          rating: averageRating.round(),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalRatings ${totalRatings == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No ratings yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showAddRatingButton) ...[
              ElevatedButton.icon(
                onPressed: widget.onAddRating,
                icon: const Icon(Icons.star_border),
                label: const Text('Rate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008faf),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> statistics) {
    final starDistribution = statistics['star_distribution'] as Map<String, dynamic>? ?? {};
    final totalRatings = statistics['total_ratings'] ?? 0;
    final recommendationPercentage = statistics['recommendation_percentage'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RatingBarChart(
              starDistribution: starDistribution.map((key, value) => MapEntry(key, value as int)),
              totalRatings: totalRatings,
            ),
            if (recommendationPercentage > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${recommendationPercentage.toStringAsFixed(1)}% would recommend',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatings(Map<String, dynamic> detailedAverages) {
    final categories = {
      'communication': {'label': 'Communication', 'icon': Icons.chat},
      'bedside_manner': {'label': 'Bedside Manner', 'icon': Icons.favorite},
      'waiting_time': {'label': 'Waiting Time', 'icon': Icons.access_time},
      'knowledge': {'label': 'Knowledge', 'icon': Icons.school},
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Ratings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.entries.map((entry) {
              final rating = (detailedAverages[entry.key] ?? 0.0).toDouble();
              final category = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: const Color(0xFF008faf),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    StarRatingWidget(
                      rating: rating.round(),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList(List<dynamic> ratings) {
    if (ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ratings.take(5).map((rating) => _buildRatingItem(rating)).toList(),
            if (ratings.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to full ratings page
                  },
                  child: Text('View all ${ratings.length} reviews'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(dynamic rating) {
    final overallRating = rating['overall_rating'] ?? 0;
    final comment = rating['comment'] as String?;
    final raterName = rating['rater_name'] ?? 'Anonymous';
    final createdAt = rating['created_at'] as String?;
    final recommendation = rating['recommendation'] as String?;

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    StarRatingWidget(
                      rating: overallRating,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      raterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (date != null)
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (recommendation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRecommendationColor(recommendation).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRecommendationColor(recommendation).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRecommendationIcon(recommendation),
                    size: 12,
                    color: _getRecommendationColor(recommendation),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Would${recommendation == 'no' ? " not" : recommendation == 'maybe' ? " maybe" : ""} recommend',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRecommendationColor(recommendation),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoRatingsMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ratings yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your experience!',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.showAddRatingButton && widget.onAddRating != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onAddRating,
                icon: const Icon(Icons.star),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008faf),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'yes':
        return Colors.green;
      case 'maybe':
        return Colors.orange;
      case 'no':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecommendationIcon(String recommendation) {
    switch (recommendation) {
      case 'yes':
        return Icons.thumb_up;
      case 'maybe':
        return Icons.help_outline;
      case 'no':
        return Icons.thumb_down;
      default:
        return Icons.help_outline;
    }
  }
}