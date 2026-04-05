import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/drive_link.dart';

class LinksProvider extends ChangeNotifier {
  final List<DriveLink> _links = [];
  static const String _storageKey = 'drive_links';
  final Uuid _uuid = const Uuid();

  List<DriveLink> get links => List.unmodifiable(_links);

  DriveLink? get activeLink {
    try {
      return _links.firstWhere((link) => link.isSelected);
    } catch (_) {
      return null;
    }
  }

  LinksProvider() {
    loadLinks();
  }

  Future<void> loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _links.clear();
      _links.addAll(DriveLink.decodeList(data));
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, DriveLink.encodeList(_links));
  }

  Future<void> addLink({
    required String name,
    required String url,
    required bool isVerified,
  }) async {
    final folderId = DriveLink.extractFolderId(url);
    if (folderId == null) throw Exception('Invalid Drive folder link');

    _links.add(
      DriveLink(
        id: _uuid.v4(),
        name: name,
        url: url,
        folderId: folderId,
        isSelected: _links.isEmpty,
        isVerified: isVerified,
      ),
    );

    await _save();
    notifyListeners();
  }

  Future<void> addCreatedFolder({
    required String name,
    required String folderId,
  }) async {
    _links.add(
      DriveLink(
        id: _uuid.v4(),
        name: name,
        url: folderId,
        folderId: folderId,
        isSelected: _links.isEmpty,
        isVerified: true,
      ),
    );

    await _save();
    notifyListeners();
  }

  Future<void> deleteLink(String id) async {
    final wasSelected = _links.any((e) => e.id == id && e.isSelected);
    _links.removeWhere((e) => e.id == id);

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