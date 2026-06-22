import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/blog_service.dart';
import '../../models/blog/blog_model.dart';
import '../../models/blog/blog_response.dart';
import 'blog_detail_page.dart';

class TrendsListPage extends StatefulWidget {
  const TrendsListPage({Key? key}) : super(key: key);

  @override
  State<TrendsListPage> createState() => _TrendsListPageState();
}

class _TrendsListPageState extends State<TrendsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Blog> trendingBlogs = [];
  List<Blog> featuredBlogs = [];
  List<Blog> recentBlogs = [];
  List<Blog> allBlogs = [];
  
  bool isLoadingTrends = true;
  bool isLoadingAll = false;
  String? trendsError;
  String? allBlogsError;
  
  int currentPage = 1;
  bool hasMorePages = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLatestTrends();
    _loadAllBlogs();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoadingAll &&
          hasMorePages &&
          _tabController.index == 3) {
        _loadMoreBlogs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestTrends() async {
    try {
      setState(() {
        isLoadingTrends = true;
        trendsError = null;
      });

      final response = await BlogService.getLatestTrends();
      setState(() {
        trendingBlogs = response.data.trending;
        featuredBlogs = response.data.featured;
        recentBlogs = response.data.recent;
        isLoadingTrends = false;
      });
    } catch (e) {
      setState(() {
        trendsError = e.toString();
        isLoadingTrends = false;
      });
    }
  }

  Future<void> _loadAllBlogs({bool isRefresh = false}) async {
    try {
      setState(() {
        isLoadingAll = true;
        if (isRefresh) {
          allBlogsError = null;
          currentPage = 1;
          allBlogs.clear();
        }
      });

      final response = await BlogService.getBlogs(
        page: isRefresh ? 1 : currentPage,
        perPage: 10,
      );

      setState(() {
        if (isRefresh) {
          allBlogs = response.data;
        } else {
          allBlogs.addAll(response.data);
        }
        hasMorePages = response.pagination?.hasNextPage ?? false;
        isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        allBlogsError = e.toString();
        isLoadingAll = false;
      });
    }
  }

  Future<void> _loadMoreBlogs() async {
    if (!hasMorePages || isLoadingAll) return;
    
    currentPage++;
    await _loadAllBlogs();
  }

  Widget _buildBlogCard(Blog blog) {
    return GestureDetector(
      onTap: () {
        context.push('/blog/${blog.slug}');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: blog.imageUrl.isNotEmpty
                      ? Image.network(
                          blog.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey[500], size: 50),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey[500], size: 50),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (blog.isTrending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TRENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (blog.isFeatured)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Excerpt
                  if (blog.excerpt != null)
                    Text(
                      blog.excerpt!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Meta info
                  Row(
                    children: [
                      if (blog.authorName != null) ...[
                        Icon(Icons.person, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          blog.authorName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        blog.displayDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        blog.viewsCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (blog.tags != null && blog.tags!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: blog.tags!.take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008faf).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF008faf).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF008faf),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogList(List<Blog> blogs, {bool showLoading = false}) {
    if (blogs.isEmpty && !showLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No blogs available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _tabController.index == 3 ? _scrollController : null,
      itemCount: blogs.length + (showLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= blogs.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildBlogCard(blogs[index]);
      },
    );
  }

  Widget _buildErrorView(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load blogs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008faf),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF008faf),
        title: const Text('Health Trends', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Featured'),
            Tab(text: 'Recent'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Trending
          isLoadingTrends
              ? const Center(child: CircularProgressIndicator())
              : trendsError != null
                  ? _buildErrorView(trendsError!, _loadLatestTrends)
                  : RefreshIndicator(
                      onRefresh: _loadLatestTrends,
                      child: _buildBlogList(trendingBlogs),
                    ),
          
          // Featured
          isLoadingTrends
              ? const Center(child: CircularProgressIndicator())
              : trendsError != null
                  ? _buildErrorView(trendsError!, _loadLatestTrends)
                  : RefreshIndicator(
                      onRefresh: _loadLatestTrends,
                      child: _buildBlogList(featuredBlogs),
                    ),
          
          // Recent
          isLoadingTrends
              ? const Center(child: CircularProgressIndicator())
              : trendsError != null
                  ? _buildErrorView(trendsError!, _loadLatestTrends)
                  : RefreshIndicator(
                      onRefresh: _loadLatestTrends,
                      child: _buildBlogList(recentBlogs),
                    ),
          
          // All
          allBlogsError != null
              ? _buildErrorView(allBlogsError!, () => _loadAllBlogs(isRefresh: true))
              : RefreshIndicator(
                  onRefresh: () => _loadAllBlogs(isRefresh: true),
                  child: _buildBlogList(allBlogs, showLoading: isLoadingAll && allBlogs.isNotEmpty),
                ),
        ],
      ),
    );
  }
}