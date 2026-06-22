import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/blog_service.dart';
import '../../models/blog/blog_model.dart';

class CreateBlogPage extends StatefulWidget {
  final Blog? blog; // For editing existing blog
  
  const CreateBlogPage({Key? key, this.blog}) : super(key: key);

  @override
  _CreateBlogPageState createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _status = 'draft';
  bool _isFeatured = false;
  bool _isTrending = false;
  File? _featuredImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.blog != null) {
      _initializeWithBlog(widget.blog!);
    }
  }

  void _initializeWithBlog(Blog blog) {
    _titleController.text = blog.title;
    _excerptController.text = blog.excerpt ?? '';
    _contentController.text = blog.content;
    _tagsController.text = blog.tags?.join(', ') ?? '';
    _status = blog.status;
    _isFeatured = blog.isFeatured;
    _isTrending = blog.isTrending;
    _existingImageUrl = blog.imageUrl.isNotEmpty ? blog.imageUrl : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _featuredImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      Blog savedBlog;
      
      if (widget.blog == null) {
        // Create new blog
        savedBlog = await BlogService.createBlog(
          title: _titleController.text,
          excerpt: _excerptController.text,
          content: _contentController.text,
          tags: tags,
          status: _status,
          isFeatured: _isFeatured,
          isTrending: _isTrending,
          featuredImage: _featuredImage,
        );
      } else {
        // Update existing blog
        savedBlog = await BlogService.updateBlog(
          blogId: widget.blog!.id,
          title: _titleController.text,
          excerpt: _excerptController.text,
          content: _contentController.text,
          tags: tags,
          status: _status,
          isFeatured: _isFeatured,
          isTrending: _isTrending,
          featuredImage: _featuredImage,
        );
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.blog == null ? 'Blog created successfully!' : 'Blog updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a bit for the SnackBar to show, then navigate to my blogs
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.push('/my-blogs');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blog == null ? 'Create Blog' : 'Edit Blog'),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            TextButton(
              onPressed: _saveBlog,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Featured Image',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _featuredImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _featuredImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Failed to load existing image: $_existingImageUrl');
                                          print('Error: $error');
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                SizedBox(height: 8),
                                                Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Tap to add featured image', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Excerpt
              TextFormField(
                controller: _excerptController,
                decoration: const InputDecoration(
                  labelText: 'Excerpt *',
                  hintText: 'A brief summary of your blog post',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an excerpt';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  hintText: 'Write your blog content here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the blog content';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Separate tags with commas (e.g., health, fitness, wellness)',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status and Feature Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Publishing Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'published', child: Text('Published')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Feature Options
                      SwitchListTile(
                        title: const Text('Featured Post'),
                        subtitle: const Text('Show this post as featured'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                      ),
                      
                      SwitchListTile(
                        title: const Text('Trending Post'),
                        subtitle: const Text('Show this post in trending section'),
                        value: _isTrending,
                        onChanged: (value) {
                          setState(() {
                            _isTrending = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button (Bottom)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBlog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.blog == null ? 'Create Blog' : 'Update Blog',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}