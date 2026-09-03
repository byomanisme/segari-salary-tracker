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
  static const String currentVersion = '1.3.10';
  static const int currentBuildNumber = 23;

  // Live remote update endpoint on user domain
  static const String manifestUrl = 'https://lukmanhakim.id/apk/version.json';
  static const String defaultDownloadUrl =
      'https://lukmanhakim.id/apk/SegariSalaryTracker-v1.3.10.apk';

  static const String _keyLastSeenVersion = 'segari_last_seen_app_version';
  static const String _keyLastSeenBuild = 'segari_last_seen_build_number';
  static const String _keySnoozeUntil = 'segari_update_snooze_until';

  // Latest Release Notes for current version (shown on first launch after update)
  static final List<String> currentWhatsNewList = [
    '👑 Rombak Dashboard Atas (Arcade HUD): Desain bagian atas kotak kosong dirombak total menjadi 3 kartu konsol modern (Skor Neon, Level & EXP Terintegrasi, Rekor Terbaik), plus bilah tombol kapsul kaca yang sangat rapi dan estetik.',
    '🎵 Efek Suara Interaktif Menarik: Suara snap balok terpasang, marimba bertingkat kombo, mega kombo arpeggio, suara maskot ulat/ular, revive, dan game over.',
    '🔊 Tombol Pengatur Suara: Ikon speaker di header atas untuk menyalakan atau membisukan suara secara instan.',
    '🎯 Drag & Drop Laser-Presisi: Titik tumpu jari (pointer drag anchor) dan bayangan papan selaras 100% tanpa gesekan atau drift.',
    '📐 Bebas Tertutup Teks: Kotak papan bawah tidak lagi tertutupi oleh tips & trick, kini berdiri kokoh dan proporsional di semua layar.',
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

        // If remote build is higher, check snooze and prompt update!
        if (updateInfo.buildNumber > currentBuildNumber) {
          // If automatic check on homescreen, check if user snoozed this specific build
          if (!isManualCheck) {
            final snoozedBuild = prefs.getInt('segari_update_snoozed_build') ?? 0;
            final snoozeStr = prefs.getString(_keySnoozeUntil);
            if (snoozedBuild == updateInfo.buildNumber && snoozeStr != null) {
              final snoozeDate = DateTime.tryParse(snoozeStr);
              if (snoozeDate != null && DateTime.now().isBefore(snoozeDate)) {
                // Still in snooze period for THIS build
                return null;
              }
            }
          }
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
  Future<void> snoozeUpdateForTomorrow({int? buildNumber}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await prefs.setString(_keySnoozeUntil, tomorrow.toIso8601String());
      if (buildNumber != null) {
        await prefs.setInt('segari_update_snoozed_build', buildNumber);
      }
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
