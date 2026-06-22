import 'package:flutter/material.dart';
import 'package:xyvra_health/widgets/star_rating_widget.dart';
import 'package:xyvra_health/services/rating_service.dart';

class RatingFormWidget extends StatefulWidget {
  final String rateableType; // 'doctor' or 'facility'
  final int rateableId;
  final String rateableName;
  final int? appointmentId;
  final VoidCallback? onRatingSubmitted;

  const RatingFormWidget({
    Key? key,
    required this.rateableType,
    required this.rateableId,
    required this.rateableName,
    this.appointmentId,
    this.onRatingSubmitted,
  }) : super(key: key);

  @override
  _RatingFormWidgetState createState() => _RatingFormWidgetState();
}

class _RatingFormWidgetState extends State<RatingFormWidget> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _overallRating = 0;
  int _communicationRating = 0;
  int _bedsideMannerRating = 0;
  int _waitingTimeRating = 0;
  int _knowledgeRating = 0;
  int _cleanlinessRating = 0;
  int _staffRating = 0;
  int _facilitiesRating = 0;
  int _accessibilityRating = 0;

  bool _isAnonymous = false;
  String? _recommendation;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.rateableType == 'doctor' ? 'Dr.' : ''} ${widget.rateableName}'),
        backgroundColor: const Color(0xFF008faf),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallRatingSection(),
              const SizedBox(height: 24),

              if (widget.rateableType == 'doctor') ...[
                _buildDoctorSpecificRatings(),
                const SizedBox(height: 24),
              ],

              if (widget.rateableType == 'facility') ...[
                _buildFacilitySpecificRatings(),
                const SizedBox(height: 24),
              ],

              _buildCommentSection(),
              const SizedBox(height: 24),

              _buildRecommendationSection(),
              const SizedBox(height: 24),

              _buildAnonymousOption(),
              const SizedBox(height: 32),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you rate your overall experience?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: InteractiveStarRating(
                initialRating: _overallRating,
                size: 40,
                onRatingChanged: (rating) {
                  setState(() {
                    _overallRating = rating;
                  });
                },
              ),
            ),
            if (_overallRating == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Please provide an overall rating',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSpecificRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Ratings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate specific aspects of your experience (optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '💬 Communication',
              'How well did the doctor communicate?',
              _communicationRating,
              (rating) => setState(() => _communicationRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '❤️ Bedside Manner',
              'How caring and compassionate was the doctor?',
              _bedsideMannerRating,
              (rating) => setState(() => _bedsideMannerRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '⏰ Waiting Time',
              'How satisfied were you with waiting times?',
              _waitingTimeRating,
              (rating) => setState(() => _waitingTimeRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '🧠 Knowledge & Expertise',
              'How knowledgeable was the doctor?',
              _knowledgeRating,
              (rating) => setState(() => _knowledgeRating = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitySpecificRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Facility Ratings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate specific aspects of the facility (optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '🧹 Cleanliness',
              'How clean was the facility?',
              _cleanlinessRating,
              (rating) => setState(() => _cleanlinessRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '👥 Staff',
              'How helpful and professional was the staff?',
              _staffRating,
              (rating) => setState(() => _staffRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '🏥 Facilities',
              'How would you rate the facilities and equipment?',
              _facilitiesRating,
              (rating) => setState(() => _facilitiesRating = rating),
            ),
            const SizedBox(height: 16),

            _buildDetailedRatingRow(
              '♿ Accessibility',
              'How accessible was the facility?',
              _accessibilityRating,
              (rating) => setState(() => _accessibilityRating = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingRow(String title, String subtitle, int rating, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: InteractiveStarRating(
            initialRating: rating,
            size: 24,
            onRatingChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Comments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your experience to help others (optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Tell us about your experience...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you recommend?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Would you recommend this ${widget.rateableType} to others?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRecommendationOption('yes', '👍 Yes', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRecommendationOption('maybe', '🤔 Maybe', Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRecommendationOption('no', '👎 No', Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationOption(String value, String label, Color color) {
    final isSelected = _recommendation == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _recommendation = _recommendation == value ? null : value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousOption() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CheckboxListTile(
          title: const Text('Submit anonymously'),
          subtitle: const Text('Your name will not be shown with this review'),
          value: _isAnonymous,
          onChanged: (value) {
            setState(() {
              _isAnonymous = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _overallRating > 0 && !_isSubmitting ? _submitRating : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008faf),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting Rating...'),
                ],
              )
            : const Text(
                'Submit Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ratingService.submitRating(
        rateableType: widget.rateableType,
        rateableId: widget.rateableId,
        overallRating: _overallRating,
        appointmentId: widget.appointmentId,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        isAnonymous: _isAnonymous,
        recommendation: _recommendation,
        // Doctor-specific ratings
        communicationRating: _communicationRating > 0 ? _communicationRating : null,
        bedsideMannerRating: _bedsideMannerRating > 0 ? _bedsideMannerRating : null,
        waitingTimeRating: _waitingTimeRating > 0 ? _waitingTimeRating : null,
        knowledgeRating: _knowledgeRating > 0 ? _knowledgeRating : null,
        // Facility-specific ratings
        cleanlinessRating: _cleanlinessRating > 0 ? _cleanlinessRating : null,
        staffRating: _staffRating > 0 ? _staffRating : null,
        facilitiesRating: _facilitiesRating > 0 ? _facilitiesRating : null,
        accessibilityRating: _accessibilityRating > 0 ? _accessibilityRating : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onRatingSubmitted != null) {
          widget.onRatingSubmitted!();
        }

        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}