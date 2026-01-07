import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';
import '../utils/app_logger.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  final MediaService _mediaService = MediaService();
  List<MediaItem> _items = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final items = await _mediaService.getGalleryItems();
      if (items.isEmpty) {
        // If empty, try syncing automatically once
        await _mediaService.syncFromHistory();
        _items = await _mediaService.getGalleryItems();
      } else {
        _items = items;
      }
    } catch (e) {
      AppLogger.error('MediaGallery', 'Failed to load items', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isLoading = true);
    await _mediaService.syncFromHistory();
    _loadData();
  }

  List<MediaItem> _filterItems(int tabIndex) {
    if (tabIndex == 0) return _items;
    if (tabIndex == 1)
      return _items.where((i) => i.type == MediaType.image).toList();
    if (tabIndex == 2)
      return _items.where((i) => i.type == MediaType.video).toList();
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的画廊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _syncData,
            tooltip: '同步历史记录',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '图片'),
            Tab(text: '视频'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(_filterItems(0)),
          _buildGrid(_filterItems(1)),
          _buildGrid(_filterItems(2)),
        ],
      ),
    );
  }

  Widget _buildGrid(List<MediaItem> items) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(child: Text('暂无媒体文件，尝试点击刷新同步'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _openDetail(item),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(item),
              if (item.type == MediaType.video)
                const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.type == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: item.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      // Video thumbnail is hard. Just verify it's a video.
      // Ideally we use a thumbnail generator but for now use a placeholder or generic icon layer on top of a color
      return Container(
        color: Colors.black87,
        child: const Icon(Icons.video_library, color: Colors.white54),
      );
    }
  }

  void _openDetail(MediaItem item) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MediaDetailScreen(item: item)));
  }
}

class MediaDetailScreen extends StatefulWidget {
  final MediaItem item;
  const MediaDetailScreen({super.key, required this.item});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  bool _isDownloading = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == MediaType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.item.url));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
      );
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.error('MediaDetail', 'Video init error', e);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    final success = await MediaService().downloadAndSave(widget.item);
    setState(() => _isDownloading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '保存成功' : '保存失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _download,
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.item.type == MediaType.image
            ? CachedNetworkImage(imageUrl: widget.item.url, fit: BoxFit.contain)
            : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
