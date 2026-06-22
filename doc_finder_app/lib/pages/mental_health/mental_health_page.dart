import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../models/api_config.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _Survey {
  final int id;
  final String title;
  final String? description;
  final String slug;
  final int questionsCount;

  _Survey({
    required this.id,
    required this.title,
    this.description,
    required this.slug,
    required this.questionsCount,
  });

  factory _Survey.fromJson(Map<String, dynamic> j) => _Survey(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        slug: j['slug'] ?? '',
        questionsCount: j['questions_count'] ?? 0,
      );
}

class _Material {
  final int id;
  final String title;
  final String? description;
  final String? imagePath;
  final String? fileType;
  final bool isFree;
  final double? price;

  _Material({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    this.fileType,
    required this.isFree,
    this.price,
  });

  factory _Material.fromJson(Map<String, dynamic> j) => _Material(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        imagePath: j['image_path'],
        fileType: j['file_type'],
        isFree: j['is_free'] == true || j['is_free'] == 1,
        price: j['price'] != null ? (j['price'] as num).toDouble() : null,
      );

  String get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return '';
    if (imagePath!.startsWith('http')) return imagePath!;
    return '${ApiConfig.webUrl}/storage/$imagePath';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _brandColor = Color(0xFF008faf);

Map<String, Map<String, dynamic>> _surveyMeta = {
  'phq-2':  {'label': 'Depression', 'color': Color(0xFF7C3AED), 'icon': Icons.psychology},
  'gad-7':  {'label': 'Anxiety',    'color': Color(0xFFEA580C), 'icon': Icons.air},
  'pss-10': {'label': 'Stress',     'color': _brandColor,       'icon': Icons.favorite},
};

Future<void> _openInAppBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({Key? key}) : super(key: key);

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage> {
  List<_Survey>  _surveys   = [];
  List<_Material> _materials = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/surveys'),   headers: {'Accept': 'application/json'}),
        http.get(Uri.parse('${ApiConfig.baseUrl}/mental-health-materials'), headers: {'Accept': 'application/json'}),
      ]);

      final surveysRes   = results[0];
      final materialsRes = results[1];

      List<_Survey>  surveys   = [];
      List<_Material> materials = [];

      if (surveysRes.statusCode == 200) {
        final body = jsonDecode(surveysRes.body);
        final data = body['data'];
        if (data is List) {
          surveys = data.map((e) => _Survey.fromJson(e)).toList();
        }
      }

      if (materialsRes.statusCode == 200) {
        final body = jsonDecode(materialsRes.body);
        final data = body['data'];
        if (data is List) {
          materials = data.map((e) => _Material.fromJson(e)).toList();
        }
      }

      if (mounted) {
        setState(() {
          _surveys   = surveys;
          _materials = materials;
          _loading   = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Failed to load content. Please try again.'; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFB),
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: const Text('Mental Wellness', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: _brandColor,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSurveysSection(),
                      const SizedBox(height: 24),
                      _buildMaterialsSection(),
                      const SizedBox(height: 16),
                      _buildDisclaimer(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screenings section ──────────────────────────────────────────────────────

  Widget _buildSurveysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006880), _brandColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.psychology, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text('FREE SCREENING TOOLS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you feeling today?',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a screening below. It opens in your browser — takes under 3 minutes and is completely confidential.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_surveys.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No screenings available yet.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._surveys.map((s) => _buildSurveyCard(s)).toList(),
      ],
    );
  }

  Widget _buildSurveyCard(_Survey s) {
    final meta  = _surveyMeta[s.slug] ?? {'label': 'Screening', 'color': Colors.grey[600]!, 'icon': Icons.help_outline};
    final color = meta['color'] as Color;
    final icon  = meta['icon'] as IconData;
    final label = meta['label'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openInAppBrowser('${ApiConfig.webAppUrl}/surveys/${s.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                        const SizedBox(width: 6),
                        Text('· ${s.questionsCount} question${s.questionsCount != 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (s.description != null && s.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(s.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Icon(Icons.open_in_browser, color: _brandColor, size: 20),
                  const SizedBox(height: 2),
                  Text('Start', style: TextStyle(fontSize: 10, color: _brandColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Resources section ───────────────────────────────────────────────────────

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.menu_book, color: _brandColor, size: 20),
            SizedBox(width: 8),
            Text('Mental Health Resources', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Expert-curated guides and tools for your wellbeing.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),

        if (_materials.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No resources available yet.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _materials.length > 12 ? 12 : _materials.length,
            itemBuilder: (_, i) => _buildMaterialCard(_materials[i]),
          ),

        if (_materials.length > 12)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () => _openInAppBrowser('${ApiConfig.webAppUrl}/mental-health'),
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('View All Resources'),
                style: OutlinedButton.styleFrom(foregroundColor: _brandColor, side: const BorderSide(color: _brandColor)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMaterialCard(_Material m) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openInAppBrowser('${ApiConfig.webAppUrl}/mental-health/${m.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  m.imageUrl.isNotEmpty
                      ? Image.network(m.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder())
                      : _imagePlaceholder(),
                  // Free/paid badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.isFree ? Colors.green : _brandColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.isFree ? 'Free' : m.price != null ? 'KES ${m.price!.toStringAsFixed(0)}' : 'Premium',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // File type pill
                  if (m.fileType != null)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(m.fileType == 'video' ? Icons.play_circle : Icons.picture_as_pdf,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(m.fileType == 'video' ? 'Video' : 'PDF',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(m.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE0F4F8),
      child: const Center(child: Icon(Icons.psychology, size: 36, color: Color(0xFF99D6E8))),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade200)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'These are screening tools, not clinical diagnoses. Always consult a qualified healthcare professional for medical advice.',
              style: TextStyle(fontSize: 11, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}
