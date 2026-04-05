class DriveFileItem {
  final String id;
  final String name;
  final String? thumbnailLink;
  final String? webContentLink;
  final String? mimeType;

  DriveFileItem({
    required this.id,
    required this.name,
    this.thumbnailLink,
    this.webContentLink,
    this.mimeType,
  });

  bool get isImage => mimeType != null && mimeType!.startsWith('image/');
}