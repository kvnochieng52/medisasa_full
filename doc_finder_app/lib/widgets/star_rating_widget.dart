import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showText;
  final bool interactive;
  final Function(int)? onRatingChanged;

  const StarRatingWidget({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showText = false,
    this.interactive = false,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            final starIndex = index + 1;
            final isActive = starIndex <= rating;

            return GestureDetector(
              onTap: interactive && onRatingChanged != null
                  ? () => onRatingChanged!(starIndex)
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? Icons.star : Icons.star_border,
                    color: isActive ? activeColor : inactiveColor,
                    size: size,
                  ),
                ),
              ),
            );
          }),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            '$rating/$maxRating',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Function(int) onRatingChanged;
  final String? label;

  const InteractiveStarRating({
    Key? key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 32.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    required this.onRatingChanged,
    this.label,
  }) : super(key: key);

  @override
  _InteractiveStarRatingState createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int currentRating;

  @override
  void initState() {
    super.initState();
    currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.maxRating, (index) {
            final starIndex = index + 1;
            final isActive = starIndex <= currentRating;

            return GestureDetector(
              onTap: () {
                setState(() {
                  currentRating = starIndex;
                });
                widget.onRatingChanged(starIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: isActive ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isActive ? Icons.star : Icons.star_border,
                      color: isActive ? widget.activeColor : widget.inactiveColor,
                      size: widget.size,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (currentRating > 0) ...[
          const SizedBox(height: 4),
          Text(
            _getRatingText(currentRating),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

class RatingDisplayWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double size;
  final bool showNumbers;
  final bool compact;

  const RatingDisplayWidget({
    Key? key,
    required this.averageRating,
    required this.totalRatings,
    this.size = 20.0,
    this.showNumbers = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: size,
          ),
          const SizedBox(width: 4),
          Text(
            averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showNumbers) ...[
            Text(
              ' ($totalRatings)',
              style: TextStyle(
                fontSize: size * 0.6,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarRatingWidget(
              rating: averageRating.round(),
              size: size,
            ),
            const SizedBox(width: 8),
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (showNumbers) ...[
          const SizedBox(height: 2),
          Text(
            '$totalRatings ${totalRatings == 1 ? 'review' : 'reviews'}',
            style: TextStyle(
              fontSize: size * 0.6,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class RatingBarChart extends StatelessWidget {
  final Map<String, int> starDistribution;
  final int totalRatings;

  const RatingBarChart({
    Key? key,
    required this.starDistribution,
    required this.totalRatings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = starDistribution[stars.toString()] ?? 0;
        final percentage = totalRatings > 0 ? count / totalRatings : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$stars',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 12,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[300],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}