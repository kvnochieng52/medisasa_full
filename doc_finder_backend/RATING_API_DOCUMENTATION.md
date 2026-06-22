# 🌟 Rating System API Documentation

## Overview
Comprehensive 1-5 star rating system for doctors and facilities with detailed feedback, comments, and creative display features for Flutter app integration.

## Features
- ⭐ **1-5 Star Ratings** for overall satisfaction
- 📊 **Detailed Category Ratings** (Communication, Bedside Manner, Waiting Time, Knowledge)
- 💬 **Optional Comments** (up to 1000 characters)
- 🔒 **Anonymous Rating** option
- ✅ **Verified Ratings** (from actual appointments)
- 📈 **Comprehensive Statistics** and analytics
- 🏆 **Top-Rated Doctors** for search results
- 👤 **User Rating History**

---

## API Endpoints

### 🎯 1. Submit Rating
**POST** `/api/ratings`

Submit a rating for a doctor or facility.

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Body
```json
{
  "rateable_type": "doctor",
  "rateable_id": 123,
  "overall_rating": 5,
  "appointment_id": 456,
  "comment": "Excellent doctor with great bedside manner!",
  "is_anonymous": false,
  "recommendation": "yes",

  // Doctor-specific ratings (1-5 stars each)
  "communication_rating": 5,
  "bedside_manner_rating": 4,
  "waiting_time_rating": 3,
  "knowledge_rating": 5
}
```

#### Field Descriptions
- `rateable_type`: `"doctor"` or `"facility"`
- `rateable_id`: ID of the doctor or facility
- `overall_rating`: **Required** 1-5 stars
- `appointment_id`: Optional - links rating to specific appointment
- `comment`: Optional comment (max 1000 chars)
- `is_anonymous`: Optional - hide user name (default: false)
- `recommendation`: Optional - `"yes"`, `"no"`, or `"maybe"`
- Doctor-specific ratings: All optional 1-5 star ratings

#### Success Response (201)
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {
    "rating_id": 789,
    "overall_rating": 5,
    "star_display": "★★★★★"
  }
}
```

#### Error Responses
```json
// Validation Error (422)
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "overall_rating": ["The overall rating must be between 1 and 5."]
  }
}

// Already Rated (409)
{
  "success": false,
  "message": "You have already rated this appointment"
}

// Doctor Not Found (404)
{
  "success": false,
  "message": "Doctor not found or not approved"
}
```

---

### 📊 2. Get Ratings for Doctor/Facility
**GET** `/api/ratings/{type}/{id}`

Get all ratings and statistics for a specific doctor or facility.

#### Parameters
- `{type}`: `doctor` or `facility`
- `{id}`: Doctor or facility ID

#### Headers
```
Authorization: Bearer {token}
```

#### Success Response (200)
```json
{
  "success": true,
  "data": {
    "ratings": [
      {
        "id": 1,
        "overall_rating": 5,
        "communication_rating": 5,
        "bedside_manner_rating": 4,
        "waiting_time_rating": 3,
        "knowledge_rating": 5,
        "comment": "Excellent doctor!",
        "recommendation": "yes",
        "is_verified": true,
        "is_anonymous": false,
        "rater_name": "John Doe",
        "created_at": "2024-10-26T10:30:00Z",
        "star_display": "★★★★★"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_ratings": 25,
      "per_page": 10
    },
    "statistics": {
      "average_rating": 4.2,
      "total_ratings": 25,
      "star_distribution": {
        "1": 1,
        "2": 2,
        "3": 5,
        "4": 7,
        "5": 10
      },
      "detailed_averages": {
        "communication": 4.5,
        "bedside_manner": 4.1,
        "waiting_time": 3.8,
        "knowledge": 4.7
      },
      "recommendation_percentage": 85.5
    }
  }
}
```

---

### 👤 3. Get User's Ratings
**GET** `/api/my-ratings`

Get all ratings submitted by the authenticated user.

#### Headers
```
Authorization: Bearer {token}
```

#### Success Response (200)
```json
{
  "success": true,
  "data": {
    "ratings": [
      {
        "id": 1,
        "overall_rating": 5,
        "comment": "Great experience!",
        "rateable": {
          "id": 123,
          "name": "Dr. John Smith",
          "specialization": "Cardiology"
        },
        "created_at": "2024-10-26T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 2,
      "total_ratings": 15,
      "per_page": 10
    }
  }
}
```

---

### 🏆 4. Get Top-Rated Doctors
**GET** `/api/top-rated-doctors`

Get doctors with highest ratings for search results and recommendations.

#### Headers
```
Authorization: Bearer {token}
```

#### Query Parameters
- `limit`: Optional - Number of doctors to return (default: 10)

#### Success Response (200)
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "Dr. Sarah Johnson",
      "email": "sarah@example.com",
      "specialization": "Cardiology",
      "experience_years": 15,
      "profile_image": "https://example.com/profile.jpg",
      "average_rating": 4.8,
      "total_ratings": 45
    },
    {
      "id": 124,
      "name": "Dr. Michael Chen",
      "specialization": "Neurology",
      "average_rating": 4.7,
      "total_ratings": 32
    }
  ]
}
```

---

## 🎨 Creative UI Implementation Ideas

### Star Rating Display
```dart
// Use the star_display from API response
Widget buildStarDisplay(String starDisplay) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: starDisplay.split('').map((char) =>
      Icon(
        char == '★' ? Icons.star : Icons.star_border,
        color: char == '★' ? Colors.amber : Colors.grey,
        size: 20,
      )
    ).toList(),
  );
}
```

### Rating Statistics Widget
```dart
Widget buildRatingStats(Map<String, dynamic> stats) {
  return Column(
    children: [
      // Overall rating
      Row(
        children: [
          Text('${stats['average_rating']}',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          buildStarDisplay('★' * stats['average_rating'].round() +
                          '☆' * (5 - stats['average_rating'].round())),
          Spacer(),
          Text('${stats['total_ratings']} reviews'),
        ],
      ),

      // Star distribution bars
      ...List.generate(5, (index) {
        int stars = 5 - index;
        int count = stats['star_distribution'][stars.toString()] ?? 0;
        double percentage = stats['total_ratings'] > 0
            ? count / stats['total_ratings'] : 0;

        return Row(
          children: [
            Text('$stars'),
            Icon(Icons.star, size: 16, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
            SizedBox(width: 8),
            Text('$count'),
          ],
        );
      }),

      // Recommendation percentage
      if (stats['recommendation_percentage'] > 0)
        Container(
          margin: EdgeInsets.only(top: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.thumb_up, color: Colors.green),
              SizedBox(width: 8),
              Text('${stats['recommendation_percentage']}% would recommend',
                   style: TextStyle(color: Colors.green[700])),
            ],
          ),
        ),
    ],
  );
}
```

### Detailed Doctor Ratings
```dart
Widget buildDetailedRatings(Map<String, dynamic> detailed) {
  final categories = {
    'communication': {'label': 'Communication', 'icon': Icons.chat},
    'bedside_manner': {'label': 'Bedside Manner', 'icon': Icons.favorite},
    'waiting_time': {'label': 'Waiting Time', 'icon': Icons.access_time},
    'knowledge': {'label': 'Knowledge', 'icon': Icons.school},
  };

  return Column(
    children: categories.entries.map((entry) {
      double rating = detailed[entry.key]?.toDouble() ?? 0;
      return ListTile(
        leading: Icon(entry.value['icon'], color: Colors.blue),
        title: Text(entry.value['label']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildStarDisplay('★' * rating.round() + '☆' * (5 - rating.round())),
            SizedBox(width: 8),
            Text('${rating.toStringAsFixed(1)}'),
          ],
        ),
      );
    }).toList(),
  );
}
```

---

## 🔍 Search Integration

To integrate ratings with search results, modify your doctor search to prioritize highly-rated doctors:

```dart
// In your doctor search API call
Future<List<Doctor>> searchDoctors({
  String? specialty,
  String? location,
  bool prioritizeRated = true,
}) async {
  final response = await api.post('/doctors/search', {
    'specialty': specialty,
    'location': location,
    'order_by_rating': prioritizeRated,
  });

  // Parse response and display ratings in search results
}
```

---

## 📱 Flutter Integration Examples

### Rating Input Form
```dart
class RatingFormWidget extends StatefulWidget {
  final int doctorId;
  final int? appointmentId;

  @override
  _RatingFormWidgetState createState() => _RatingFormWidgetState();
}

class _RatingFormWidgetState extends State<RatingFormWidget> {
  int overallRating = 0;
  int communicationRating = 0;
  int bedsideMannerRating = 0;
  int waitingTimeRating = 0;
  int knowledgeRating = 0;
  String comment = '';
  bool isAnonymous = false;
  String? recommendation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Overall rating
        Text('Overall Experience'),
        StarRating(
          rating: overallRating,
          onRatingChanged: (rating) => setState(() => overallRating = rating),
        ),

        // Detailed ratings
        buildDetailedRatingInput('Communication', communicationRating,
            (rating) => setState(() => communicationRating = rating)),
        buildDetailedRatingInput('Bedside Manner', bedsideMannerRating,
            (rating) => setState(() => bedsideMannerRating = rating)),
        buildDetailedRatingInput('Waiting Time', waitingTimeRating,
            (rating) => setState(() => waitingTimeRating = rating)),
        buildDetailedRatingInput('Knowledge', knowledgeRating,
            (rating) => setState(() => knowledgeRating = rating)),

        // Comment
        TextField(
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(labelText: 'Comment (Optional)'),
          onChanged: (value) => comment = value,
        ),

        // Anonymous option
        CheckboxListTile(
          title: Text('Submit anonymously'),
          value: isAnonymous,
          onChanged: (value) => setState(() => isAnonymous = value ?? false),
        ),

        // Recommendation
        Text('Would you recommend this doctor?'),
        Row(
          children: ['yes', 'maybe', 'no'].map((option) =>
            RadioListTile<String>(
              title: Text(option.toUpperCase()),
              value: option,
              groupValue: recommendation,
              onChanged: (value) => setState(() => recommendation = value),
            )
          ).toList(),
        ),

        // Submit button
        ElevatedButton(
          onPressed: submitRating,
          child: Text('Submit Rating'),
        ),
      ],
    );
  }

  Future<void> submitRating() async {
    try {
      final response = await api.post('/ratings', {
        'rateable_type': 'doctor',
        'rateable_id': widget.doctorId,
        'overall_rating': overallRating,
        'appointment_id': widget.appointmentId,
        'comment': comment.isNotEmpty ? comment : null,
        'is_anonymous': isAnonymous,
        'recommendation': recommendation,
        'communication_rating': communicationRating > 0 ? communicationRating : null,
        'bedside_manner_rating': bedsideMannerRating > 0 ? bedsideMannerRating : null,
        'waiting_time_rating': waitingTimeRating > 0 ? waitingTimeRating : null,
        'knowledge_rating': knowledgeRating > 0 ? knowledgeRating : null,
      });

      if (response['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error
    }
  }
}
```

---

## 🚀 Implementation Notes

1. **Authentication Required**: All endpoints require valid Bearer token
2. **Rating Validation**: All ratings must be 1-5 integers
3. **Appointment Verification**: Ratings linked to appointments are marked as verified
4. **Duplicate Prevention**: Users can only rate each appointment once
5. **Real-time Updates**: Rating statistics update immediately after submission
6. **Privacy**: Anonymous ratings hide user names but preserve statistics
7. **Search Integration**: Use `/top-rated-doctors` endpoint to enhance search results

---

## 🎯 Best Practices for Flutter Implementation

1. **Progressive Disclosure**: Show overall rating first, detailed ratings on tap
2. **Visual Feedback**: Use animations for star ratings and progress bars
3. **Contextual Ratings**: Only show rating option after completed appointments
4. **Loading States**: Show shimmer effects while loading ratings
5. **Error Handling**: Graceful fallbacks for network errors
6. **Caching**: Cache rating data to improve performance
7. **Real-time Updates**: Refresh ratings after user submits new rating

This comprehensive rating system will significantly enhance user trust and help patients find the best healthcare providers! 🌟