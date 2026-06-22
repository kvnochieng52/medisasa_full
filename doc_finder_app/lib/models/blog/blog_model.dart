import '../api_config.dart';

class Blog {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String content;
  final String? featuredImage;
  final String? authorName;
  final List<String>? tags;
  final String status;
  final bool isFeatured;
  final bool isTrending;
  final int viewsCount;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.content,
    this.featuredImage,
    this.authorName,
    this.tags,
    required this.status,
    required this.isFeatured,
    required this.isTrending,
    required this.viewsCount,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'],
      content: json['content'] ?? '',
      featuredImage: json['featured_image'],
      authorName: json['author_name'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      status: json['status'] ?? 'draft',
      isFeatured: json['is_featured'] ?? false,
      isTrending: json['is_trending'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'content': content,
      'featured_image': featuredImage,
      'author_name': authorName,
      'tags': tags,
      'status': status,
      'is_featured': isFeatured,
      'is_trending': isTrending,
      'views_count': viewsCount,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayDate {
    final date = publishedAt ?? createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String get imageUrl {
    if (featuredImage == null || featuredImage!.isEmpty) return '';
    if (featuredImage!.startsWith('http')) {
      return featuredImage!;
    }
    
    // Handle different storage formats:
    // Case 1: /storage/blog_images/filename.jpg (with leading slash)
    // Case 2: storage/blog_images/filename.jpg (without leading slash)  
    // Case 3: blog_images/filename.jpg (just the path)
    
    String cleanPath = featuredImage!;
    if (cleanPath.startsWith('/storage/')) {
      // Remove the leading /storage/ and add base URL + /storage/
      cleanPath = cleanPath.substring(9); // Remove '/storage/'
      final fullUrl = '${ApiConfig.webUrl}/storage/$cleanPath';
      print('Blog imageUrl (Case 1): featuredImage=$featuredImage, fullUrl=$fullUrl');
      return fullUrl;
    } else if (cleanPath.startsWith('storage/')) {
      // Remove the leading storage/ and add base URL + /storage/
      cleanPath = cleanPath.substring(8); // Remove 'storage/'
      final fullUrl = '${ApiConfig.webUrl}/storage/$cleanPath';
      print('Blog imageUrl (Case 2): featuredImage=$featuredImage, fullUrl=$fullUrl');
      return fullUrl;
    } else {
      // Just add base URL + /storage/
      final fullUrl = '${ApiConfig.webUrl}/storage/$cleanPath';
      print('Blog imageUrl (Case 3): featuredImage=$featuredImage, fullUrl=$fullUrl');
      return fullUrl;
    }
  }

  String get readTimeEstimate {
    final wordCount = content.split(' ').length;
    final readTime = (wordCount / 200).ceil(); // Average 200 words per minute
    return '$readTime min read';
  }
}