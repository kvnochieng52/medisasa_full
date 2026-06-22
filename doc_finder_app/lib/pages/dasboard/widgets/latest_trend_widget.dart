import 'package:flutter/material.dart';
import '../../../services/blog_service.dart';
import '../../../models/blog/blog_model.dart';
import '../../../models/blog/blog_response.dart';
import '../../blog/blog_detail_page.dart';
import '../../blog/trends_list_page.dart';

class LatestTrendWidget extends StatefulWidget {
  const LatestTrendWidget({Key? key}) : super(key: key);

  @override
  State<LatestTrendWidget> createState() => _LatestTrendWidgetState();
}

class _LatestTrendWidgetState extends State<LatestTrendWidget> {
  List<Blog> blogPosts = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTrendingBlogs();
  }

  Future<void> _loadTrendingBlogs() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final trendsData = await BlogService.getLatestTrends();
      setState(() {
        blogPosts = trendsData.data.trending.isNotEmpty 
          ? trendsData.data.trending 
          : trendsData.data.recent.take(4).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget buildBlogCard(Blog blog) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailPage(slug: blog.slug),
          ),
        );
      },
      child: SizedBox(
        width: 200,
        child: Card(
          margin: const EdgeInsets.only(right: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: blog.imageUrl.isNotEmpty
                        ? Image.network(
                            blog.imageUrl,
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 90,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey[500], size: 30),
                            ),
                          )
                        : Container(
                            height: 90,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey[500], size: 30),
                          ),
                  ),
                  if (blog.isTrending)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (blog.isFeatured)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            blog.displayDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          blog.viewsCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue, size: 15),
                const SizedBox(width: 8),
                const Text(
                  'Latest Trends',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isLoading && blogPosts.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrendsListPage(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, 
                                   color: Colors.grey[400], size: 30),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load trends',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadTrendingBlogs,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Retry', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        )
                      : blogPosts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.article, 
                                       color: Colors.grey[400], size: 30),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No trending blogs available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: blogPosts.length,
                              itemBuilder: (context, index) =>
                                  buildBlogCard(blogPosts[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
