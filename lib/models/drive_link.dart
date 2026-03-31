import 'dart:convert';

class DriveLink {
  final String id;
  String name;
  String url;
  String folderId;
  bool isSelected;

  DriveLink({
    required this.id,
    required this.name,
    required this.url,
    required this.folderId,
    this.isSelected = false,
  });

  static String? extractFolderId(String input) {
    input = input.trim();

    final folderPattern = RegExp(r'folders/([a-zA-Z0-9_-]+)');
    final folderMatch = folderPattern.firstMatch(input);
    if (folderMatch != null) return folderMatch.group(1);

    final idPattern = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final idMatch = idPattern.firstMatch(input);
    if (idMatch != null) return idMatch.group(1);

    if (RegExp(r'^[a-zA-Z0-9_-]{10,}$').hasMatch(input)) return input;

    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'folderId': folderId,
    'isSelected': isSelected,
  };

  factory DriveLink.fromJson(Map<String, dynamic> json) => DriveLink(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    folderId: json['folderId'],
    isSelected: json['isSelected'] ?? false,
  );

  static String encodeList(List<DriveLink> links) {
    return jsonEncode(links.map((e) => e.toJson()).toList());
  }

  static List<DriveLink> decodeList(String data) {
    final list = jsonDecode(data) as List;
    return list.map((e) => DriveLink.fromJson(e)).toList();
  }
}