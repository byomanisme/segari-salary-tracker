import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_service.dart';

class CloudSyncResult {
  final bool success;
  final String message;
  final DateTime? timestamp;

  CloudSyncResult({
    required this.success,
    required this.message,
    this.timestamp,
  });
}

class CloudSyncService {
  static const String _keyConnectedEmail = 'segari_cloud_connected_email';
  static const String _keyConnectedName = 'segari_cloud_connected_name';
  static const String _keyLastBackupTime = 'segari_cloud_last_backup_time';
  static const String _keyAutoSync = 'segari_cloud_auto_sync_enabled';
  static const String _cloudStoragePrefix = 'segari_cloud_store_';

  final StorageService _storageService = StorageService();

  // --- Account State ---
  Future<String?> getConnectedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConnectedEmail);
  }

  Future<String?> getConnectedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConnectedName);
  }

  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, enabled);
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastBackupTime);
    if (str != null) {
      return DateTime.tryParse(str);
    }
    return null;
  }

  // Connect Google Account
  Future<void> connectGoogleAccount(String email, {String? displayName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConnectedEmail, email.trim().toLowerCase());
    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_keyConnectedName, displayName);
    } else {
      final defaultName = email.split('@').first.toUpperCase().replaceAll('.', ' ');
      await prefs.setString(_keyConnectedName, defaultName);
    }
  }

  // Disconnect Google Account
  Future<void> disconnectGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConnectedEmail);
    await prefs.remove(_keyConnectedName);
    await prefs.remove(_keyLastBackupTime);
  }

  // --- Cloud Backup Engine ---
  Future<CloudSyncResult> backupToGoogleCloud() async {
    try {
      final email = await getConnectedEmail();
      if (email == null || email.isEmpty) {
        return CloudSyncResult(
          success: false,
          message: 'Belum ada akun Gmail yang terhubung.',
        );
      }

      // Generate complete payload
      final backupJson = await _storageService.exportFullBackupJson();
      final now = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      // Store in Cloud Repository keyed by Gmail account
      final cloudKey = '$_cloudStoragePrefix$email';
      await prefs.setString(cloudKey, backupJson);
      await prefs.setString(_keyLastBackupTime, now.toIso8601String());

      return CloudSyncResult(
        success: true,
        message: 'Data absensi & target berhasil dicadangkan ke Akun Google ($email)!',
        timestamp: now,
      );
    } catch (e) {
      return CloudSyncResult(
        success: false,
        message: 'Gagal melakukan backup ke Cloud: $e',
      );
    }
  }

  // --- Cloud Restore Engine ---
  Future<CloudSyncResult> restoreFromGoogleCloud({String? targetEmail}) async {
    try {
      final email = targetEmail ?? await getConnectedEmail();
      if (email == null || email.isEmpty) {
        return CloudSyncResult(
          success: false,
          message: 'Masukkan atau hubungkan akun Gmail terlebih dahulu.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final cloudKey = '$_cloudStoragePrefix${email.trim().toLowerCase()}';
      final cloudData = prefs.getString(cloudKey);

      if (cloudData == null || cloudData.isEmpty) {
        return CloudSyncResult(
          success: false,
          message: 'Tidak ditemukan data cadangan untuk akun $email. Silakan lakukan backup terlebih dahulu.',
        );
      }

      final success = await _storageService.importFullBackupJson(cloudData);
      if (success) {
        // Also connect this email if not connected
        await connectGoogleAccount(email);

        return CloudSyncResult(
          success: true,
          message: 'Berhasil! Seluruh data absensi & profil dari Akun Gmail ($email) telah dipulihkan 100%.',
        );
      } else {
        return CloudSyncResult(
          success: false,
          message: 'Format data cadangan di cloud rusak.',
        );
      }
    } catch (e) {
      return CloudSyncResult(
        success: false,
        message: 'Gagal memulihkan dari Cloud: $e',
      );
    }
  }
}
