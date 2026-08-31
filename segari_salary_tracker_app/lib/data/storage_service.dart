import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import 'initial_data.dart';

class StorageService {
  static const String _keyRecords = 'segari_attendance_records';
  static const String _keySettings = 'segari_user_settings';
  static const String _keyPenalties = 'segari_penalties';
  static const String _keySkuEntries = 'segari_sku_entries';

  // --- Settings ---
  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySettings);
    if (jsonStr != null) {
      try {
        return UserSettings.fromJson(jsonStr);
      } catch (e) {
        // fallback
      }
    }
    return UserSettings();
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, settings.toJson());
  }

  // --- Attendance Records ---
  Future<List<AttendanceRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyRecords);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final records = list.map((e) => AttendanceRecord.fromMap(e)).toList();
        records.sort((a, b) => a.date.compareTo(b.date));
        return records;
      } catch (e) {
        // fallback to initial
      }
    }

    final initialRecords = getInitialAttendanceRecords();
    await saveRecords(initialRecords);
    return initialRecords;
  }

  Future<void> saveRecords(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((e) => e.toMap()).toList();
    await prefs.setString(_keyRecords, json.encode(list));
  }

  Future<void> addOrUpdateRecord(AttendanceRecord record) async {
    final records = await getRecords();
    final index = records.indexWhere((r) => r.id == record.id || r.date == record.date);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    records.sort((a, b) => a.date.compareTo(b.date));
    await saveRecords(records);
  }

  Future<void> deleteRecord(String id) async {
    final records = await getRecords();
    records.removeWhere((r) => r.id == id);
    await saveRecords(records);
  }

  // --- Penalties ---
  Future<List<ComplaintPenalty>> getPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPenalties);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final penalties = list.map((e) => ComplaintPenalty.fromJson(e)).toList();
        penalties.sort((a, b) => a.date.compareTo(b.date));
        return penalties;
      } catch (e) {
        // fallback
      }
    }
    return [];
  }

  Future<void> savePenalties(List<ComplaintPenalty> penalties) async {
    final prefs = await SharedPreferences.getInstance();
    final list = penalties.map((e) => e.toJson()).toList();
    await prefs.setString(_keyPenalties, json.encode(list));
  }

  Future<void> addOrUpdatePenalty(ComplaintPenalty penalty) async {
    final list = await getPenalties();
    final idx = list.indexWhere((p) => p.id == penalty.id);
    if (idx >= 0) {
      list[idx] = penalty;
    } else {
      list.add(penalty);
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    await savePenalties(list);
  }

  Future<void> deletePenalty(String id) async {
    final list = await getPenalties();
    list.removeWhere((p) => p.id == id);
    await savePenalties(list);
  }

  // --- SKU Entries ---
  Future<List<SkuEntry>> getSkuEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySkuEntries);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = json.decode(jsonStr);
        final entries = list.map((e) => SkuEntry.fromJson(e)).toList();
        entries.sort((a, b) => a.date.compareTo(b.date));
        return entries;
      } catch (e) {
        // fallback
      }
    }
    return [];
  }

  Future<void> saveSkuEntries(List<SkuEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_keySkuEntries, json.encode(list));
  }

  Future<void> addOrUpdateSkuEntry(SkuEntry entry) async {
    final list = await getSkuEntries();
    final idx = list.indexWhere((e) => e.id == entry.id || e.date == entry.date);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    await saveSkuEntries(list);
  }

  Future<void> deleteSkuEntry(String id) async {
    final list = await getSkuEntries();
    list.removeWhere((e) => e.id == id);
    await saveSkuEntries(list);
  }

  Future<void> resetToInitial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecords);
    await prefs.remove(_keyPenalties);
    await prefs.remove(_keySkuEntries);
    final initialRecords = getInitialAttendanceRecords();
    await saveRecords(initialRecords);
  }

  // --- Backup & Restore Engine (Pindah Perangkat) ---
  Future<String> exportFullBackupJson() async {
    final settings = await getSettings();
    final records = await getRecords();
    final penalties = await getPenalties();
    final skuEntries = await getSkuEntries();

    final Map<String, dynamic> backupData = {
      'app': 'Sesaat Apps - Segari Salary Tracker',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'settings': json.decode(settings.toJson()),
      'records': records.map((e) => e.toMap()).toList(),
      'penalties': penalties.map((e) => e.toJson()).toList(),
      'sku_entries': skuEntries.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<bool> importFullBackupJson(String jsonContent) async {
    try {
      final dynamic decoded = json.decode(jsonContent);
      if (decoded is! Map<String, dynamic>) return false;

      // Import settings
      if (decoded.containsKey('settings')) {
        final settings = UserSettings.fromMap(decoded['settings']);
        await saveSettings(settings);
      }

      // Import records
      if (decoded.containsKey('records') && decoded['records'] is List) {
        final List<AttendanceRecord> records = (decoded['records'] as List)
            .map((e) => AttendanceRecord.fromMap(e))
            .toList();
        records.sort((a, b) => a.date.compareTo(b.date));
        await saveRecords(records);
      }

      // Import penalties
      if (decoded.containsKey('penalties') && decoded['penalties'] is List) {
        final List<ComplaintPenalty> penalties = (decoded['penalties'] as List)
            .map((e) => ComplaintPenalty.fromJson(e))
            .toList();
        penalties.sort((a, b) => a.date.compareTo(b.date));
        await savePenalties(penalties);
      }

      // Import sku entries
      if (decoded.containsKey('sku_entries') && decoded['sku_entries'] is List) {
        final List<SkuEntry> entries = (decoded['sku_entries'] as List)
            .map((e) => SkuEntry.fromJson(e))
            .toList();
        entries.sort((a, b) => a.date.compareTo(b.date));
        await saveSkuEntries(entries);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
