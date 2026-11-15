import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// Cache Entry containing data and timestamp
/// ═══════════════════════════════════════════════════════════════
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  const CacheEntry({
    required this.data,
    required this.timestamp,
  });

  bool isFresh(Duration maxAge) {
    return DateTime.now().difference(timestamp) < maxAge;
  }
}

/// ═══════════════════════════════════════════════════════════════
/// High-Performance Stale-While-Revalidate Cache Manager
/// 0ms Memory Layer + Persistent SharedPreferences Disk Layer
/// ═══════════════════════════════════════════════════════════════
class CacheManager {
  final SharedPreferences _prefs;
  final Map<String, CacheEntry> _memoryCache = {};

  static const String _keyPrefix = 'sw_cache_';
  static const String _tsPrefix = 'sw_cache_ts_';

  CacheManager(this._prefs);

  /// Synchronously retrieves cached data:
  /// 1. From RAM memory (0ms)
  /// 2. Or from SharedPreferences in-memory store (0ms)
  dynamic get(String key) {
    // 1. Check RAM memory cache
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.data;
    }

    // 2. Check SharedPreferences disk backing
    final rawString = _prefs.getString('$_keyPrefix$key');
    if (rawString != null && rawString.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawString);
        final tsMillis = _prefs.getInt('$_tsPrefix$key') ?? 0;
        final timestamp = DateTime.fromMillisecondsSinceEpoch(tsMillis);

        // Store into RAM cache for subsequent instant lookups
        _memoryCache[key] = CacheEntry(data: decoded, timestamp: timestamp);
        return decoded;
      } catch (e) {
        debugPrint('⚠️ Error decoding cache key "$key": $e');
      }
    }
    return null;
  }

  /// Synchronously retrieves a parsed JSON Map
  Map<String, dynamic>? getJsonMap(String key) {
    final data = get(key);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Synchronously retrieves a parsed JSON List
  List<dynamic>? getJsonList(String key) {
    final data = get(key);
    if (data is List) return data;
    return null;
  }

  /// Writes data to memory cache immediately and persists to disk
  Future<void> put(String key, dynamic data) async {
    final now = DateTime.now();
    _memoryCache[key] = CacheEntry(data: data, timestamp: now);

    try {
      final jsonString = jsonEncode(data);
      await Future.wait([
        _prefs.setString('$_keyPrefix$key', jsonString),
        _prefs.getInt('$_tsPrefix$key') == now.millisecondsSinceEpoch
            ? Future.value(true)
            : _prefs.setInt('$_tsPrefix$key', now.millisecondsSinceEpoch),
      ]);
    } catch (e) {
      debugPrint('⚠️ Failed to persist cache key "$key" to storage: $e');
    }
  }

  /// Returns the DateTime when this key was last saved/revalidated
  DateTime? getLastUpdated(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.timestamp;
    }
    final tsMillis = _prefs.getInt('$_tsPrefix$key');
    if (tsMillis != null && tsMillis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(tsMillis);
    }
    return null;
  }

  /// Returns true if the cached entry was fetched within [maxAge]
  /// (Default: 25 seconds debounce/throttle threshold)
  bool isFresh(String key, {Duration maxAge = const Duration(seconds: 25)}) {
    final lastUpdated = getLastUpdated(key);
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated) < maxAge;
  }

  /// Removes an entry from memory and disk
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs.remove('$_keyPrefix$key');
    await _prefs.remove('$_tsPrefix$key');
  }

  /// Clears all cached items
  Future<void> clearAll() async {
    _memoryCache.clear();
    final keysToRemove = _prefs
        .getKeys()
        .where((k) => k.startsWith(_keyPrefix) || k.startsWith(_tsPrefix))
        .toList();
    for (final k in keysToRemove) {
      await _prefs.remove(k);
    }
  }
}

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheManager(prefs);
});

