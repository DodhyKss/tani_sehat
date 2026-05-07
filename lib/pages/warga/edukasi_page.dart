import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({super.key});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _rekomendasi = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final meResult = await _api.getMe();
      String? katTd;
      String? katGad;
      if (meResult['success'] == true) {
        final status = meResult['data']?['status_kesehatan'];
        katTd = status?['kategori_td'];
        katGad = status?['kategori_gad'];
      }
      
      final result = await _api.getRekomendasi(kategoriTd: katTd, kategoriGad: katGad);
      if (result['success'] == true) {
        _rekomendasi = result['data'] ?? {};
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: 'Edukasi', subtitle: 'Materi rekomendasi untuk Anda'),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textLight,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.play_circle_outline, size: 20), text: 'Video'),
                Tab(icon: Icon(Icons.article_outlined, size: 20), text: 'Materi'),
                Tab(icon: Icon(Icons.image_outlined, size: 20), text: 'Gambar'),
                Tab(icon: Icon(Icons.fitness_center, size: 20), text: 'Olahraga'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideoTab(),
                      _buildMateriTab(),
                      _buildGambarTab(),
                      _buildOlahragaTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTab() {
    final videos = _rekomendasi['videos'] as List? ?? [];
    if (videos.isEmpty) return const EmptyState(icon: Icons.videocam_off, title: 'Belum ada video');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (_, i) {
          final v = videos[i];
          return YoutubeVideoItem(videoData: v);
        },
      ),
    );
  }

  Widget _buildMateriTab() {
    final materiList = _rekomendasi['materis'] as List? ?? [];
    if (materiList.isEmpty) return const EmptyState(icon: Icons.article_outlined, title: 'Belum ada materi');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: materiList.length,
        itemBuilder: (_, i) {
          final m = materiList[i];
          return InkWell(
            onTap: () {
              final path = m['file_path'] ?? '';
              if (path.isEmpty) return;
              // Encode only spaces to avoid issues with slashes being encoded by encodeComponent
              final safePath = path.replaceAll(' ', '%20');
              final url = '${_api.baseUrl}/file?path=$safePath';
              _showPdfViewer(context, url, m['judul'] ?? 'Materi');
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentWarm.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.article_rounded, color: AppTheme.accentWarm, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['judul'] ?? m['nama'] ?? 'Materi',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text(m['deskripsi'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGambarTab() {
    final gambarList = _rekomendasi['gambars'] as List? ?? [];
    if (gambarList.isEmpty) return const EmptyState(icon: Icons.image_not_supported, title: 'Belum ada gambar');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
        ),
        itemCount: gambarList.length,
        itemBuilder: (_, i) {
          final g = gambarList[i];
          final imageUrl = g['file_path'] ?? g['url'] ?? '';
          final fullUrl = imageUrl.isNotEmpty ? '${_api.baseUrl}/file?path=$imageUrl' : '';
          return InkWell(
            onTap: () {
              if (fullUrl.isEmpty) return;
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(fullUrl, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        label: const Text('Tutup'),
                      )
                    ]
                  )
                )
              );
            },
            child: Container(
              decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: fullUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(fullUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40, color: AppTheme.textLight))),
                          )
                        : const Center(child: Icon(Icons.image, size: 40, color: AppTheme.textLight)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(g['judul'] ?? g['nama'] ?? 'Infografis',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildOlahragaTab() {
    final olahragaList = _rekomendasi['olahragas'] as List? ?? [];
    if (olahragaList.isEmpty) return const EmptyState(icon: Icons.fitness_center, title: 'Belum ada rekomendasi olahraga');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: olahragaList.length,
        itemBuilder: (_, i) {
          final o = olahragaList[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o['nama_olahraga'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _tag(o['kategori_td'] ?? '', AppTheme.danger),
                    _tag(o['kategori_gad'] ?? '', AppTheme.info),
                  ],
                ),
              ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _tag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showPdfViewer(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                tooltip: 'Buka di Browser',
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          body: FutureBuilder<Uint8List>(
            future: _fetchPdfBytes(url),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                        const SizedBox(height: 16),
                        Text('Gagal memuat PDF: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final uri = Uri.parse(url);
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: const Text('Buka di Browser Saja'),
                        )
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) return const Center(child: Text('Tidak ada data PDF'));
              
              return SfPdfViewer.memory(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _fetchPdfBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.toLowerCase().contains('pdf') && response.bodyBytes.length < 1000) {
        throw Exception('Data yang diterima bukan PDF yang valid.');
      }
      return response.bodyBytes;
    } else {
      throw Exception('Server merespon dengan status: ${response.statusCode}');
    }
  }
}

class YoutubeVideoItem extends StatelessWidget {
  final Map videoData;
  const YoutubeVideoItem({Key? key, required this.videoData}) : super(key: key);

  Widget _tag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showVideoModal(BuildContext context, String videoId) {
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppTheme.primary,
          progressColors: const ProgressBarColors(
            playedColor: AppTheme.primary,
            handleColor: AppTheme.primary,
          ),
        ),
        builder: (context, player) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: player,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    if (controller.value.isFullScreen) {
                      controller.toggleFullScreenMode();
                    }
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Tutup Video'),
                )
              ]
            ),
          );
        },
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final url = videoData['link_embed'] ?? '';
    final String? videoId = YoutubePlayer.convertUrlToId(url);

    return InkWell(
      onTap: () {
        if (videoId != null && videoId.isNotEmpty) {
          _showVideoModal(context, videoId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video tidak valid atau tidak didukung.')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(videoData['judul'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _tag(videoData['kategori_td'] ?? '', AppTheme.danger),
                    _tag(videoData['kategori_gad'] ?? '', AppTheme.info),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
