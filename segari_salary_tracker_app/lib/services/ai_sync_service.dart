import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_service.dart';

class AiSyncResult {
  final bool isSuccess;
  final String message;
  final DateTime? syncedAt;
  final int recordsCount;
  final int skuCount;
  final int penaltiesCount;

  AiSyncResult({
    required this.isSuccess,
    required this.message,
    this.syncedAt,
    this.recordsCount = 0,
    this.skuCount = 0,
    this.penaltiesCount = 0,
  });
}

class AiSyncService {
  static const String _syncEndpoint =
      'https://lukmanhakim.id/api/sync_ai.php?key=segari_lukman_sync_2026';
  static const String _keyLastAiSync = 'segari_last_ai_sync_timestamp';

  final StorageService _storageService = StorageService();

  /// Ambil waktu sinkronisasi terakhir ke AI Cloud
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyLastAiSync);
      if (str != null) {
        return DateTime.tryParse(str);
      }
    } catch (e) {
      debugPrint('Error reading last AI sync time: $e');
    }
    return null;
  }

  /// Sinkronkan seluruh snapshot data HP ke server AI
  Future<AiSyncResult> syncToAiCloud() async {
    try {
      final jsonPayload = await _storageService.exportFullBackupJson();

      final response = await http
          .post(
            Uri.parse(_syncEndpoint),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final now = DateTime.now();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastAiSync, now.toIso8601String());

        return AiSyncResult(
          isSuccess: true,
          message: decoded['message'] ?? 'Data berhasil disinkronkan ke AI!',
          syncedAt: now,
          recordsCount: decoded['records_count'] ?? 0,
          skuCount: decoded['sku_count'] ?? 0,
          penaltiesCount: decoded['penalties_count'] ?? 0,
        );
      } else {
        return AiSyncResult(
          isSuccess: false,
          message: 'Gagal terhubung ke server (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Error syncing data to AI: $e');
      return AiSyncResult(
        isSuccess: false,
        message: 'Koneksi gagal: $e. Pastikan HP terhubung ke internet.',
      );
    }
  }

  /// Buat teks ringkasan rapi untuk di-paste langsung ke chat AI jika offline
  Future<String> generateAiTextSummary() async {
    final settings = await _storageService.getSettings();
    final records = await _storageService.getRecords();
    final skuEntries = await _storageService.getSkuEntries();
    final penalties = await _storageService.getPenalties();

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Filter bulan berjalan
    final monthRecords = records.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.month == currentMonth && d.year == currentYear;
    }).toList();

    final monthSku = skuEntries.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.month == currentMonth && d.year == currentYear;
    }).toList();

    final monthPenalties = penalties.where((p) {
      final d = DateTime.tryParse(p.date);
      return d != null && d.month == currentMonth && d.year == currentYear;
    }).toList();

    int totalHours = 0;
    int offCount = 0;
    int mp3Count = 0;
    int regulerCount = 0;
    int doubleMp3Count = 0;
    int regulerMp3Count = 0;
    int totalBaseSalary = 0;

    for (final r in monthRecords) {
      totalHours += r.totalHours;
      totalBaseSalary += r.rate;
      switch (r.type) {
        case 'off':
          offCount++;
          break;
        case 'mp3':
          mp3Count++;
          break;
        case 'double_mp3':
          doubleMp3Count++;
          break;
        case 'reguler':
          regulerCount++;
          break;
        case 'reguler_mp3':
          regulerMp3Count++;
          break;
      }
    }

    int totalSkuMonth = 0;
    for (final s in monthSku) {
      totalSkuMonth += s.count;
    }

    final earnedBonus = settings.getBonusForSku(totalSkuMonth);
    final achievedTier = settings.getAchievedTierLevel(totalSkuMonth);

    int totalPenaltyMonth = 0;
    for (final p in monthPenalties) {
      totalPenaltyMonth += p.amount;
    }

    final netSalary = totalBaseSalary + earnedBonus - totalPenaltyMonth;

    final currFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final numFormat = NumberFormat('#,###', 'id_ID');

    final buffer = StringBuffer();
    buffer.writeln('=== SNAPSHOT DATA GAJIKU SEGARI UNTUK ANALISIS AI ===');
    buffer.writeln('Waktu Ekspor: ${DateFormat('dd MMMM yyyy HH:mm').format(now)}');
    buffer.writeln('Pekerja: ${settings.name} (${settings.empId})');
    buffer.writeln('Periode: ${DateFormat('MMMM yyyy').format(now)}');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('📅 RINGKASAN SHIFT KERJA:');
    buffer.writeln('- Total Kehadiran Aktif: ${monthRecords.length - offCount} Hari');
    buffer.writeln('- Hari Libur (OFF): $offCount Hari');
    buffer.writeln('- Total Jam Kerja: $totalHours Jam');
    buffer.writeln('  * Reguler 8 Jam: $regulerCount Hari');
    buffer.writeln('  * Reguler + Lembur 11 Jam: $regulerMp3Count Hari');
    buffer.writeln('  * MP3H 3 Jam: $mp3Count Hari');
    buffer.writeln('  * Double MP3H 6 Jam: $doubleMp3Count Hari');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('📦 TARGET SKU PACKING:');
    buffer.writeln('- Total SKU Bulan Ini: ${numFormat.format(totalSkuMonth)} SKU');
    buffer.writeln('- Status Tier: Tier $achievedTier (${settings.getSeverityTierLabel(totalSkuMonth)})');
    buffer.writeln('- Estimasi Bonus SKU: +${currFormat.format(earnedBonus)}');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('⚠️ DENDA KOMPLAIN QC:');
    buffer.writeln('- Kasus Komplain: ${monthPenalties.length} Kasus');
    buffer.writeln('- Total Potongan Denda: -${currFormat.format(totalPenaltyMonth)}');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('💰 ESTIMASI GAJI BERSIH SEMENTARA:');
    buffer.writeln('- Gaji Pokok & Shift: ${currFormat.format(totalBaseSalary)}');
    buffer.writeln('- Bonus SKU: +${currFormat.format(earnedBonus)}');
    buffer.writeln('- Potongan Denda: -${currFormat.format(totalPenaltyMonth)}');
    buffer.writeln('👉 ESTIMASI TAKE HOME PAY: ${currFormat.format(netSalary)}');
    buffer.writeln('====================================================');
    buffer.writeln('Catatan: Tolong berikan analisis performa, peluang Severity 1, dan evaluasi keuangan saya.');

    return buffer.toString();
  }
}
