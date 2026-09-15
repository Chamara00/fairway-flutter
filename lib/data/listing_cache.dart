import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/listing_page.dart';

class ListingCache {
  ListingCache(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'cached_listings_v1';
  static const _savedAtKey = 'cached_listings_saved_at_v1';

  Future<void> save(ListingPage page) async {
    await _prefs.setString(_key, jsonEncode(page.toJson()));
    await _prefs.setInt(_savedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  ListingPage? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return ListingPage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      clear();
      return null;
    }
  }

  DateTime? savedAt() {
    final ms = _prefs.getInt(_savedAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_savedAtKey);
  }
}
