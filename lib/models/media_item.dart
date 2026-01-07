import 'package:hive/hive.dart';

part 'media_item.g.dart';

@HiveType(typeId: 4) // Ensure typeId is unique. Check other models.
enum MediaType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
}

@HiveType(typeId: 5) // Ensure typeId is unique.
class MediaItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final MediaType type;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String conversationId;

  @HiveField(5)
  final String? localPath; // For downloaded files, optional

  @HiveField(6)
  final String? prompt;

  MediaItem({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
    required this.conversationId,
    this.localPath,
    this.prompt,
  });
}
