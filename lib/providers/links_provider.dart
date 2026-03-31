import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/drive_link.dart';

class LinksProvider extends ChangeNotifier {
  final List<DriveLink> _links = [];
  static const String _key = 'Camscene_links';
  final Uuid _uuid = const Uuid();

  List<DriveLink> get links => List.unmodifiable(_links);

  DriveLink? get activeLink {
    try {
      return _links.firstWhere((l) => l.isSelected);
    } catch (_) {
      return null;
    }
  }

  LinksProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data != null && data.isNotEmpty) {
        _links.clear();
        _links.addAll(DriveLink.decodeList(data));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load links error: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DriveLink.encodeList(_links));
  }

  Future<void> addLink({
    required String name,
    required String url,
  }) async {
    final folderId = DriveLink.extractFolderId(url);
    if (folderId == null) throw Exception('Invalid Drive folder link');

    _links.add(DriveLink(
      id: _uuid.v4(),
      name: name.trim(),
      url: url.trim(),
      folderId: folderId,
      isSelected: _links.isEmpty,
    ));

    await _save();
    notifyListeners();
  }

  Future<void> updateLink({
    required String id,
    required String name,
    required String url,
  }) async {
    final folderId = DriveLink.extractFolderId(url);
    if (folderId == null) throw Exception('Invalid Drive folder link');

    final index = _links.indexWhere((l) => l.id == id);
    if (index == -1) return;

    _links[index]
      ..name = name.trim()
      ..url = url.trim()
      ..folderId = folderId;

    await _save();
    notifyListeners();
  }

  Future<void> deleteLink(String id) async {
    final wasSelected = _links.any((l) => l.id == id && l.isSelected);
    _links.removeWhere((l) => l.id == id);
    if (wasSelected && _links.isNotEmpty) {
      _links.first.isSelected = true;
    }
    await _save();
    notifyListeners();
  }

  Future<void> selectLink(String id) async {
    for (final link in _links) {
      link.isSelected = link.id == id;
    }
    await _save();
    notifyListeners();
  }
}