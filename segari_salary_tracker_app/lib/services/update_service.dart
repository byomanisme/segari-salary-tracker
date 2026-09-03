import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final String title;
  final List<String> changelog;
  final String downloadUrl;
  final bool isMandatory;

  AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.title,
    required this.changelog,
    required this.downloadUrl,
    this.isMandatory = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? '1.3.0',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 6,
      releaseDate: json['releaseDate'] as String? ?? 'Terbaru',
      title: json['title'] as String? ?? 'Pembaruan Aplikasi Tersedia',
      changelog: (json['changelog'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Peningkatan performa dan pembaruan maskot.'],
      downloadUrl: json['downloadUrl'] as String? ??
          'https://lukmanhakim.id/apk/SegariSalaryTracker-v1.3.0.apk',
      isMandatory: json['isMandatory'] as bool? ?? false,
    );
  }
}

class UpdateService {
  static const String currentVersion = '1.3.7';
  static const int currentBuildNumber = 20;

  // Live remote update endpoint on user domain
  static const String manifestUrl = 'https://lukmanhakim.id/apk/version.json';
  static const String defaultDownloadUrl =
      'https://lukmanhakim.id/apk/SegariSalaryTracker-v1.3.7.apk';

  static const String _keyLastSeenVersion = 'segari_last_seen_app_version';
  static const String _keyLastSeenBuild = 'segari_last_seen_build_number';
  static const String _keySnoozeUntil = 'segari_update_snooze_until';

  // Latest Release Notes for current version (shown on first launch after update)
  static final List<String> currentWhatsNewList = [
    '🧠 Anti-Deadlock Smart Spawner: Algoritma cerdas resmi Block Blast! Menjamin minimal 1 balok selalu muat, tidak ada lagi Game Over mendadak yang tidak adil.',
    '🎯 Skala Balok di Jari 1:1 Presisi: Saat balok diangkat, ukurannya membesar secara mulus persis sama dengan ukuran kotak di papan (100% akurat).',
    '🍃 Mode Santai (Untimed Classic): Bebas berpikir rileks tanpa tekanan countdown timer 60s, lengkap dengan tombol switch mode.',
    '✨ Pembersihan Ghost Preview: Bayangan balok hanya menyala jika posisi valid; kotak merah silang (X) yang mengotori layar resmi dihapus.',
    '💎 Balok Kristal 3D Glossy: Desain balok diperbarui dengan tekstur kristal beveled dan kilau cahaya sudut atas yang sangat memanjakan mata.',
    '⚡ Kesempatan Kedua (Revive): Fitur penyelamat yang membersihkan area 4x4 tengah papan saat buntu untuk menyelamatkan kombo dan rekor skor tinggi.',
    '💥 Ledakan Cube Shatter & Micro-Shake: Efek serpihan kubus 3D pecah berputar dan getaran mikro pada papan saat terjadi kombo baris.',
    '🎶 Respon Tactile Bertingkat: Tangga getaran haptic dan audio klik dinamis mengikuti tingkatan kombo (Do-Re-Mi-Fa-Sol).',
  ];

  /// Check if the user just updated the app to show "What's New"
  Future<bool> shouldShowWhatsNew() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenBuild = prefs.getInt(_keyLastSeenBuild) ?? 0;
      final lastSeen = prefs.getString(_keyLastSeenVersion);
      if (lastSeenBuild < currentBuildNumber || lastSeen != currentVersion) {
        return true;
      }
    } catch (e) {
      debugPrint('shouldShowWhatsNew error: $e');
    }
    return false;
  }

  /// Mark current version as seen so "What's New" is only shown once
  Future<void> markWhatsNewSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSeenBuild, currentBuildNumber);
      await prefs.setString(_keyLastSeenVersion, currentVersion);
    } catch (e) {
      debugPrint('markWhatsNewSeen error: $e');
    }
  }

  /// Check if a newer version is available from remote server
  Future<AppUpdateInfo?> checkForUpdate({bool isManualCheck = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // If automatic check on homescreen, check if user snoozed it until tomorrow
      if (!isManualCheck) {
        final snoozeStr = prefs.getString(_keySnoozeUntil);
        if (snoozeStr != null) {
          final snoozeDate = DateTime.tryParse(snoozeStr);
          if (snoozeDate != null && DateTime.now().isBefore(snoozeDate)) {
            // Still in snooze period (will prompt tomorrow)
            return null;
          }
        }
      }

      // Fetch live version manifest from lukmanhakim.id with cache-buster
      final cacheBusterUrl =
          '$manifestUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.get(
        Uri.parse(cacheBusterUrl),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = AppUpdateInfo.fromJson(data);

        // If remote build is higher, prompt update!
        if (updateInfo.buildNumber > currentBuildNumber) {
          return updateInfo;
        }
      }

      return null;
    } catch (e) {
      debugPrint('checkForUpdate info: $e (offline or server not yet reachable)');
      return null;
    }
  }

  /// Snooze update reminder until tomorrow
  Future<void> snoozeUpdateForTomorrow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await prefs.setString(_keySnoozeUntil, tomorrow.toIso8601String());
    } catch (e) {
      debugPrint('snoozeUpdateForTomorrow error: $e');
    }
  }

  static const MethodChannel _installerChannel =
      MethodChannel('com.segari.salarytracker/installer');

  /// Install APK directly via native Android PackageInstaller
  static Future<bool> installApk(String filePath) async {
    try {
      final bool? success = await _installerChannel
          .invokeMethod<bool>('installApk', {'filePath': filePath});
      return success ?? false;
    } catch (e) {
      debugPrint('installApk native channel error: $e');
      return false;
    }
  }

  /// Open download URL (fallback)
  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
