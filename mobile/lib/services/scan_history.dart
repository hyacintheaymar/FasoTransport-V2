import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryStore {
  static const _key = 'fasotransport_scan_history';

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<void> addEntry(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();
    current.insert(0, entry);
    await prefs.setString(_key, jsonEncode(current));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
