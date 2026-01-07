import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../cache/hive_service.dart';
import '../models/media_item.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final HiveService _hive = HiveService();
  final Dio _dio = Dio();

  /// 获取画廊列表
  Future<List<MediaItem>> getGalleryItems() async {
    return await _hive.getAllMediaItems();
  }

  /// 从历史会话同步数据 (手动触发或初始化时调用)
  Future<void> syncFromHistory() async {
    debugPrint('🔄 开始同步历史媒体数据...');
    final conversations = await _hive.getAllConversations();
    int count = 0;

    for (final conv in conversations) {
      final messages = await _hive.getMessages(conv.id);
      for (final msg in messages) {
        // 这里的逻辑其实已经在 HiveService.addMessage 中有了
        // 但为了处理旧数据，我们需要手动触发一次检查
        // 不过 HiveService.addMessage 包含保存逻辑，我们可以复用类似的逻辑

        if (msg.metadata != null && msg.metadata!.containsKey('mediaUrl')) {
          try {
            final mediaUrl = msg.metadata!['mediaUrl'] as String;
            if (mediaUrl.isNotEmpty) {
              // 检查是否已存在 (简单检查ID)
              // 由于 MediaItem ID = Message ID，我们可以直接 put，Hive 会覆盖或更新
              // 但为了避免不必要的IO，可以检查是否存在? Hive put操作还好。

              MediaType? mediaType;
              final lowerUrl = mediaUrl.toLowerCase();

              if (lowerUrl.endsWith('.mp4') ||
                  lowerUrl.endsWith('.mov') ||
                  lowerUrl.endsWith('.avi')) {
                mediaType = MediaType.video;
              } else if (lowerUrl.endsWith('.png') ||
                  lowerUrl.endsWith('.jpg') ||
                  lowerUrl.endsWith('.jpeg') ||
                  lowerUrl.endsWith('.webp') ||
                  lowerUrl.endsWith('.gif')) {
                mediaType = MediaType.image;
              }

              if (mediaType != null) {
                final item = MediaItem(
                  id: msg.id,
                  url: mediaUrl,
                  type: mediaType,
                  createdAt: msg.createdAt,
                  conversationId: msg.conversationId,
                  prompt: msg.content,
                );
                await _hive.saveMediaItem(item);
                count++;
              }
            }
          } catch (_) {}
        }
      }
    }
    debugPrint('✅ 同步完成，共处理 $count 个媒体项');
  }

  /// 下载并保存到相册
  Future<bool> downloadAndSave(MediaItem item) async {
    try {
      // 1. 请求权限 (Gal 自动处理，但也支持手动)
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2. 下载文件
      final tempDir = await getTemporaryDirectory();
      var extension = 'png';
      if (item.type == MediaType.video) extension = 'mp4';

      // 尝试从 URL 获取后缀
      if (item.url.contains('.')) {
        final ext = item.url.split('.').last.split('?').first.toLowerCase();
        if (['png', 'jpg', 'jpeg', 'webp', 'gif', 'mp4', 'mov', 'avi']
            .contains(ext)) {
          extension = ext;
        }
      }

      final fileName = 'download_${item.id}.$extension';
      final savePath = '${tempDir.path}/$fileName';

      debugPrint('📥 开始下载: ${item.url}');
      await _dio.download(item.url, savePath);

      // 3. 保存到相册
      debugPrint('💾 保存到相册: $savePath');
      if (item.type == MediaType.video) {
        await Gal.putVideo(savePath, album: 'VigoAI');
      } else {
        await Gal.putImage(savePath, album: 'VigoAI');
      }

      debugPrint('✅ 保存成功');
      return true;
    } catch (e) {
      debugPrint('❌ 下载保存失败: $e');
      if (e is GalException) {
        debugPrint('GalException: ${e.type} - $e');
      }
      return false;
    }
  }
}
