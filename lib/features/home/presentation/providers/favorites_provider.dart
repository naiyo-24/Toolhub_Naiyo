import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final DateTime addedAt;

  FavoriteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'bgColor': bgColor.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      title: json['title'],
      subtitle: json['subtitle'],
      icon: _deserializeIcon(json['iconCodePoint'], json['iconFontFamily']),
      bgColor: Color(json['bgColor']),
      iconColor: Color(json['iconColor']),
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  static IconData _deserializeIcon(int codePoint, String? fontFamily) {
    // Bypass tree-shaker
    final IconData Function(int, {String? fontFamily, String? fontPackage, bool matchTextDirection}) createIcon = IconData.new;
    return createIcon(codePoint, fontFamily: fontFamily);
  }
}

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favJson = prefs.getString('favorite_tools');
    if (favJson != null) {
      final List<dynamic> decoded = jsonDecode(favJson);
      state = decoded.map((item) => FavoriteItem.fromJson(item)).toList();
    }
  }

  Future<void> _saveFavorites(List<FavoriteItem> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(favorites.map((e) => e.toJson()).toList());
    await prefs.setString('favorite_tools', encoded);
  }

  void toggleFavorite(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    final existingIndex = state.indexWhere((item) => item.title == title);
    
    if (existingIndex >= 0) {
      // Remove it
      final updatedList = List<FavoriteItem>.from(state)..removeAt(existingIndex);
      state = updatedList;
      _saveFavorites(updatedList);
    } else {
      // Add it
      final newItem = FavoriteItem(
        title: title,
        subtitle: subtitle,
        icon: icon,
        bgColor: bgColor,
        iconColor: iconColor,
        addedAt: DateTime.now(),
      );
      final updatedList = List<FavoriteItem>.from(state)..add(newItem);
      state = updatedList;
      _saveFavorites(updatedList);
    }
  }

  bool isFavorite(String title) {
    return state.any((item) => item.title == title);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteItem>>((ref) {
  return FavoritesNotifier();
});
