import 'package:flutter/material.dart';

/// Maps string keys to constant [IconData] values.
///
/// This is required for Flutter release builds — the tree shaker cannot
/// handle dynamic `IconData(codePoint)` constructions and will fail with
/// "non-constant instances of IconData" during `flutter build apk/ipa`.
///
/// To add a new icon: pick any Icons.xxx constant, add it here with a
/// descriptive string key, then use that key in your Category model.
abstract class AppIcons {
  static const Map<String, IconData> _map = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'sports_esports': Icons.sports_esports,
    'favorite': Icons.favorite,
    'checkroom': Icons.checkroom,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'computer': Icons.computer,
    'shopping_cart': Icons.shopping_cart,
    'local_cafe': Icons.local_cafe,
    'fitness_center': Icons.fitness_center,
    'flight': Icons.flight,
    'school': Icons.school,
    'pets': Icons.pets,
    'phone': Icons.phone,
    'tv': Icons.tv,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'sports': Icons.sports,
    'child_care': Icons.child_care,
    'local_hospital': Icons.local_hospital,
    'attach_money': Icons.attach_money,
    'card_giftcard': Icons.card_giftcard,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'business': Icons.business,
    'star': Icons.star,
    'subscriptions': Icons.subscriptions,
  };

  /// Returns the [IconData] for the given [key].
  /// Falls back to [Icons.category] if the key is not found.
  static IconData get(String key) => _map[key] ?? Icons.category;

  /// All available icon keys — used when building the icon picker UI.
  static List<String> get keys => _map.keys.toList();
}
