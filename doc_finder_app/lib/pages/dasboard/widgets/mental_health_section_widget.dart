import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../models/api_config.dart';

// ── Lightweight models ────────────────────────────────────────────────────────

class _Survey {
  final int id;
  final String title;
  final String slug;
  final int questionsCount;

  _Survey({required this.id, required this.title, required this.slug, required this.questionsCount});

  factory _Survey.fromJson(Map<String, dynamic> j) => _Survey(
        id: j['id'],
        title: j['title'] ?? '',
        slug: j['slug'] ?? '',
        questionsCount: j['questions_count'] ?? 0,
      );
}

class _Material {
  final int id;
  final String title;
  final String? imagePath;
  final String? fileType;
  final bool isFree;
  final double? price;

  _Material({required this.id, required this.title, this.imagePath, this.fileType, required this.isFree, this.price});

  factory _Material.fromJson(Map<String, dynamic> j) => _Material(
        id: j['id'],
        title: j['title'] ?? '',
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

const _brand = Color(0xFF008faf);
const _brandDark = Color(0xFF006880);

const Map<String, Map<String, dynamic>> _surveyMeta = {
  'phq-2':  {'label': 'Depression', 'color': Color(0xFF7C3AED), 'icon': Icons.psychology},
  'gad-7':  {'label': 'Anxiety',    'color': Color(0xFFEA580C), 'icon': Icons.air},
  'pss-10': {'label': 'Stress',     'color': _brand,            'icon': Icons.favorite},
};

Future<void> _openBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

// ── Widget ────────────────────────────────────────────────────────────────────

class MentalHealthSectionWidget extends StatefulWidget {
  const MentalHealthSectionWidget({Key? key}) : super(key: key);

  @override
  State<MentalHealthSectionWidget> createState() => _MentalHealthSectionWidgetState();
}

class _MentalHealthSectionWidgetState extends State<MentalHealthSectionWidget> {
  List<_Survey>   _surveys   = [];
  List<_Material> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/surveys'),               headers: {'Accept': 'application/json'}),
        http.get(Uri.parse('${ApiConfig.baseUrl}/mental-health-materials'), headers: {'Accept': 'application/json'}),
      ]);

      List<_Survey>   surveys   = [];
      List<_Material> materials = [];

      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body)['data'];
        if (d is List) surveys = d.map((e) => _Survey.fromJson(e)).toList();
      }
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body)['data'];
        if (d is List) materials = d.map((e) => _Material.fromJson(e)).toList();
      }

      if (mounted) setState(() { _surveys = surveys; _materials = materials; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.psychology, color: _brand, size: 18),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mental Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  Text('Screenings & wellness resources', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/mental-health'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All', style: TextStyle(color: _brand, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_loading)
          _buildShimmer()
        else ...[
          // ── Screenings banner ─────────────────────────────────────────────
          if (_surveys.isNotEmpty) ...[
            _buildScreeningsBanner(),
            const SizedBox(height: 12),
          ],

          // ── Resources horizontal scroll ───────────────────────────────────
          if (_materials.isNotEmpty) ...[
            _buildResourcesRow(),
          ],
        ],
      ],
    );
  }

  // ── Screenings banner ───────────────────────────────────────────────────────

  Widget _buildScreeningsBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_brandDark, _brand], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white70, size: 11),
                    SizedBox(width: 4),
                    Text('FREE SCREENING TOOLS', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('How are you feeling today?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Tap a screening below — opens in your browser, takes under 3 min.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 10),
          ..._surveys.map((s) => _buildSurveyTile(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildSurveyTile(_Survey s) {
    final meta  = _surveyMeta[s.slug] ?? {'label': 'Screening', 'color': Colors.grey[400]!, 'icon': Icons.help_outline};
    final color = meta['color'] as Color;
    final icon  = meta['icon'] as IconData;
    final label = meta['label'] as String;

    return GestureDetector(
      onTap: () => _openBrowser('${ApiConfig.webAppUrl}/surveys/${s.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withValues(alpha: 1.0))),
                      ),
                      const SizedBox(width: 5),
                      Text('· ${s.questionsCount} questions', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(s.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.open_in_browser, color: Colors.white60, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Resources horizontal row ────────────────────────────────────────────────

  Widget _buildResourcesRow() {
    final visible = _materials.length > 6 ? _materials.sublist(0, 6) : _materials;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == visible.length) return _buildViewAllCard();
          return _buildMaterialCard(visible[i]);
        },
      ),
    );
  }

  Widget _buildMaterialCard(_Material m) {
    return GestureDetector(
      onTap: () => _openBrowser('${ApiConfig.webAppUrl}/mental-health/${m.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or placeholder
              m.imageUrl.isNotEmpty
                  ? Image.network(m.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Free/paid badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: m.isFree ? Colors.green : _brand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.isFree ? 'Free' : 'KES ${m.price?.toStringAsFixed(0) ?? '–'}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // File type
              if (m.fileType != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Icon(m.fileType == 'video' ? Icons.play_arrow : Icons.picture_as_pdf, color: Colors.white, size: 10),
                  ),
                ),
              // Title at bottom
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  m.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: () => context.push('/mental-health'),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brand.withValues(alpha: 0.25), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded, color: _brand, size: 22),
            SizedBox(height: 6),
            Text('View\nAll', textAlign: TextAlign.center, style: TextStyle(color: _brand, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE0F4F8),
      child: const Center(child: Icon(Icons.psychology, size: 30, color: Color(0xFF99D6E8))),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: Row(
            children: List.generate(4, (_) => Container(
              width: 110,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            )),
          ),
        ),
      ],
    );
  }
}
