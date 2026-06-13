import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

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
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final videos = await _api.getVideo();
      final materis = await _api.getMateri();
      final gambars = await _api.getGambar();
      final olahragas = await _api.getOlahraga();

      _rekomendasi = {
        'videos': videos,
        'materis': materis,
        'gambars': gambars,
        'olahragas': olahragas,
      };
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      body: Column(children: [
        const GradientHeader(title: 'Edukasi', subtitle: 'Materi rekomendasi untuk Anda'),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary, unselectedLabelColor: AppTheme.textLight,
            indicatorColor: AppTheme.primary, indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: Responsive.sp(12)),
            tabs: [
              Tab(icon: Icon(Icons.play_circle_outline, size: Responsive.icon(20)), text: 'Video'),
              Tab(icon: Icon(Icons.article_outlined, size: Responsive.icon(20)), text: 'Materi'),
              Tab(icon: Icon(Icons.image_outlined, size: Responsive.icon(20)), text: 'Gambar'),
              Tab(icon: Icon(Icons.fitness_center, size: Responsive.icon(20)), text: 'Olahraga'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : TabBarView(controller: _tabController, children: [_buildVideoTab(), _buildMateriTab(), _buildGambarTab(), _buildOlahragaTab()]),
        ),
      ]),
    );
  }

  Widget _buildVideoTab() {
    final videos = _rekomendasi['videos'] as List? ?? [];
    if (videos.isEmpty) return const EmptyState(icon: Icons.videocam_off, title: 'Belum ada video');
    return RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)), itemCount: videos.length,
      itemBuilder: (_, i) => YoutubeVideoItem(videoData: videos[i]),
    ));
  }

  Widget _buildMateriTab() {
    final materiList = _rekomendasi['materis'] as List? ?? [];
    if (materiList.isEmpty) return const EmptyState(icon: Icons.article_outlined, title: 'Belum ada materi');
    return RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)), itemCount: materiList.length,
      itemBuilder: (_, i) {
        final m = materiList[i];
        return InkWell(
          onTap: () {
            final path = m['file_path'] ?? '';
            if (path.isEmpty) return;
            
            _api.logFrekuensiEdukasi('materi');
            
            final safePath = path.replaceAll(' ', '%20');
            _showPdfViewer(context, '${_api.baseUrl}/file?path=$safePath', m['judul'] ?? 'Materi');
          },
          child: Container(
            margin: EdgeInsets.only(bottom: Responsive.h(12)),
            padding: EdgeInsets.all(Responsive.pad(14)),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(Responsive.pad(10)),
                decoration: BoxDecoration(color: AppTheme.accentWarm.withOpacity(0.12), borderRadius: BorderRadius.circular(Responsive.radius(12))),
                child: Icon(Icons.article_rounded, color: AppTheme.accentWarm, size: Responsive.icon(22)),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['judul'] ?? m['nama'] ?? 'Materi', style: TextStyle(fontSize: Responsive.sp(14), fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                SizedBox(height: Responsive.h(4)),
                Text(m['deskripsi'] ?? '', style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textMedium), maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        );
      },
    ));
  }

  Widget _buildGambarTab() {
    final gambarList = _rekomendasi['gambars'] as List? ?? [];
    if (gambarList.isEmpty) return const EmptyState(icon: Icons.image_not_supported, title: 'Belum ada gambar');
    final cols = Responsive.isTablet ? 3 : 2;
    return RefreshIndicator(onRefresh: _loadData, child: GridView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: Responsive.w(12), mainAxisSpacing: Responsive.w(12), childAspectRatio: 0.85),
      itemCount: gambarList.length,
      itemBuilder: (_, i) {
        final g = gambarList[i];
        final imageUrl = g['file_path'] ?? g['url'] ?? '';
        final fullUrl = imageUrl.isNotEmpty ? '${_api.baseUrl}/file?path=$imageUrl' : '';
        return InkWell(
          onTap: () {
            if (fullUrl.isEmpty) return;
            
            _api.logFrekuensiEdukasi('gambar');
            
            showDialog(context: context, builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent, insetPadding: EdgeInsets.all(Responsive.pad(16)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(borderRadius: BorderRadius.circular(Responsive.radius(16)), child: Image.network(fullUrl, fit: BoxFit.contain)),
                SizedBox(height: Responsive.h(16)),
                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close), label: const Text('Tutup')),
              ]),
            ));
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(16)))),
                child: fullUrl.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(16))), child: Image.network(fullUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, size: Responsive.icon(40), color: AppTheme.textLight))))
                    : Center(child: Icon(Icons.image, size: Responsive.icon(40), color: AppTheme.textLight)),
              )),
              Padding(
                padding: EdgeInsets.all(Responsive.pad(10)),
                child: Text(g['judul'] ?? g['nama'] ?? 'Infografis', style: TextStyle(fontSize: Responsive.sp(12), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      },
    ));
  }

  Widget _buildOlahragaTab() {
    final olahragaList = _rekomendasi['olahragas'] as List? ?? [];
    if (olahragaList.isEmpty) return const EmptyState(icon: Icons.fitness_center, title: 'Belum ada rekomendasi olahraga');
    return RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)), itemCount: olahragaList.length,
      itemBuilder: (_, i) {
        final o = olahragaList[i];
        return Container(
          margin: EdgeInsets.only(bottom: Responsive.h(12)),
          padding: EdgeInsets.all(Responsive.pad(14)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(Responsive.pad(10)),
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(Responsive.radius(14))),
              child: Icon(Icons.fitness_center, color: Colors.white, size: Responsive.icon(22)),
            ),
            SizedBox(width: Responsive.w(12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['nama_olahraga'] ?? '', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              SizedBox(height: Responsive.h(6)),
              Wrap(spacing: 6, runSpacing: 4, children: [_tag(o['kategori_td'] ?? '', AppTheme.danger), _tag(o['kategori_gad'] ?? '', AppTheme.info)]),
            ])),
          ]),
        );
      },
    ));
  }

  Widget _tag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(8), vertical: Responsive.pad(3)),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(6))),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: Responsive.sp(9), fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showPdfViewer(BuildContext context, String url, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.open_in_browser), tooltip: 'Buka di Browser', onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        })],
      ),
      body: FutureBuilder<Uint8List>(
        future: _fetchPdfBytes(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          if (snapshot.hasError) return Center(child: Padding(padding: EdgeInsets.all(Responsive.pad(24)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: Responsive.icon(48), color: AppTheme.danger),
            SizedBox(height: Responsive.h(16)),
            Text('Gagal memuat PDF: ${snapshot.error}', textAlign: TextAlign.center),
            SizedBox(height: Responsive.h(24)),
            ElevatedButton(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), child: const Text('Buka di Browser Saja')),
          ])));
          if (!snapshot.hasData) return const Center(child: Text('Tidak ada data PDF'));
          return SfPdfViewer.memory(snapshot.data!);
        },
      ),
    )));
  }

  Future<Uint8List> _fetchPdfBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.toLowerCase().contains('pdf') && response.bodyBytes.length < 1000) throw Exception('Data yang diterima bukan PDF yang valid.');
      return response.bodyBytes;
    } else { throw Exception('Server merespon dengan status: ${response.statusCode}'); }
  }
}

class YoutubeVideoItem extends StatelessWidget {
  final Map videoData;
  const YoutubeVideoItem({Key? key, required this.videoData}) : super(key: key);

  Widget _tag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(8), vertical: Responsive.pad(3)),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(6))),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: Responsive.sp(10), fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showVideoModal(BuildContext context, String videoId) {
    final controller = YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: false));
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => YoutubePlayerBuilder(
      player: YoutubePlayer(controller: controller, showVideoProgressIndicator: true, progressIndicatorColor: AppTheme.primary, progressColors: const ProgressBarColors(playedColor: AppTheme.primary, handleColor: AppTheme.primary)),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () { 
              if (controller.value.isFullScreen) controller.toggleFullScreenMode(); 
              Navigator.pop(ctx); 
            }
          ),
        ),
        body: Center(child: player),
      ),
    ))).then((_) => controller.dispose());
  }

  String? _extractVideoId(String url) {
    if (url.isEmpty) return null;
    if (url.toLowerCase().contains('<iframe') && url.toLowerCase().contains('src="')) {
      final startIndex = url.toLowerCase().indexOf('src="') + 5;
      final endIndex = url.indexOf('"', startIndex);
      if (endIndex > startIndex) url = url.substring(startIndex, endIndex);
    }
    if (url.contains('youtu.be/')) return url.split('youtu.be/')[1].split('?')[0];
    if (url.contains('v=')) return url.split('v=')[1].split('&')[0];
    if (url.contains('embed/')) return url.split('embed/')[1].split('?')[0];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final url = videoData['link_embed'] ?? '';
    final String? videoId = _extractVideoId(url);
    return InkWell(
      onTap: () {
        if (videoId != null && videoId.isNotEmpty) {
          ApiService().logFrekuensiEdukasi('video');
          _showVideoModal(context, videoId);
        }
        else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video tidak valid atau tidak didukung.')));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.h(12)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: Responsive.h(140),
            width: double.infinity,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(16)))),
            child: Center(child: Icon(Icons.play_circle_fill, size: Responsive.icon(50), color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.all(Responsive.pad(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(videoData['judul'] ?? '', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              SizedBox(height: Responsive.h(8)),
              Wrap(spacing: 6, runSpacing: 4, children: [_tag(videoData['kategori_td'] ?? '', AppTheme.danger), _tag(videoData['kategori_gad'] ?? '', AppTheme.info)]),
            ]),
          ),
        ]),
      ),
    );
  }
}
