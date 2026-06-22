import 'blog_model.dart';

class BlogListResponse {
  final bool success;
  final List<Blog> data;
  final PaginationInfo? pagination;

  BlogListResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory BlogListResponse.fromJson(Map<String, dynamic> json) {
    return BlogListResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? (json['data'] as List).map((item) => Blog.fromJson(item)).toList()
          : [],
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
    );
  }

  // Convenience getter for accessing blogs
  List<Blog> get blogs => data;
}

class BlogDetailResponse {
  final bool success;
  final BlogDetailData data;

  BlogDetailResponse({
    required this.success,
    required this.data,
  });

  factory BlogDetailResponse.fromJson(Map<String, dynamic> json) {
    return BlogDetailResponse(
      success: json['success'] ?? false,
      data: BlogDetailData.fromJson(json['data']),
    );
  }
}

class BlogDetailData {
  final Blog blog;
  final List<Blog> relatedBlogs;

  BlogDetailData({
    required this.blog,
    required this.relatedBlogs,
  });

  factory BlogDetailData.fromJson(Map<String, dynamic> json) {
    return BlogDetailData(
      blog: Blog.fromJson(json['blog']),
      relatedBlogs: json['related_blogs'] != null
          ? (json['related_blogs'] as List)
              .map((item) => Blog.fromJson(item))
              .toList()
          : [],
    );
  }
}

class LatestTrendsResponse {
  final bool success;
  final LatestTrendsData data;

  LatestTrendsResponse({
    required this.success,
    required this.data,
  });

  factory LatestTrendsResponse.fromJson(Map<String, dynamic> json) {
    return LatestTrendsResponse(
      success: json['success'] ?? false,
      data: LatestTrendsData.fromJson(json['data']),
    );
  }
}

class LatestTrendsData {
  final List<Blog> trending;
  final List<Blog> featured;
  final List<Blog> recent;

  LatestTrendsData({
    required this.trending,
    required this.featured,
    required this.recent,
  });

  factory LatestTrendsData.fromJson(Map<String, dynamic> json) {
    return LatestTrendsData(
      trending: json['trending'] != null
          ? (json['trending'] as List)
              .map((item) => Blog.fromJson(item))
              .toList()
          : [],
      featured: json['featured'] != null
          ? (json['featured'] as List)
              .map((item) => Blog.fromJson(item))
              .toList()
          : [],
      recent: json['recent'] != null
          ? (json['recent'] as List).map((item) => Blog.fromJson(item)).toList()
          : [],
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}