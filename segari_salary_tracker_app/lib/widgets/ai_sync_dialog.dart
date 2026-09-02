import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/ai_sync_service.dart';
import '../data/storage_service.dart';

class AiSyncDialog extends StatefulWidget {
  const AiSyncDialog({Key? key}) : super(key: key);

  @override
  State<AiSyncDialog> createState() => _AiSyncDialogState();
}

class _AiSyncDialogState extends State<AiSyncDialog> {
  final AiSyncService _aiSyncService = AiSyncService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  DateTime? _lastSyncTime;
  String? _statusFeedback;
  bool _isSuccessFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadSyncTime();
  }

  Future<void> _loadSyncTime() async {
    final t = await _aiSyncService.getLastSyncTime();
    setState(() => _lastSyncTime = t);
  }

  Future<void> _handleCloudSync() async {
    setState(() {
      _isLoading = true;
      _statusFeedback = null;
    });

    final result = await _aiSyncService.syncToAiCloud();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccessFeedback = result.isSuccess;
      if (result.isSuccess) {
        _lastSyncTime = result.syncedAt;
        _statusFeedback =
            '✅ Berhasil! Data (${result.recordsCount} shift, ${result.skuCount} SKU) telah terkirim ke server AI. Sekarang Anda bisa meminta AI di PC untuk menganalisis data Anda.';
      } else {
        _statusFeedback = '❌ ${result.message}';
      }
    });
  }

  Future<void> _handleCopySummary() async {
    final summary = await _aiSyncService.generateAiTextSummary();
    await Clipboard.setData(ClipboardData(text: summary));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Teks ringkasan data berhasil disalin ke clipboard! Siap di-paste ke chat AI.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleShareJson() async {
    try {
      final jsonContent = await _storageService.exportFullBackupJson();
      final bytes = Uint8List.fromList(jsonContent.codeUnits);
      final filename =
          'segari_data_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membagikan file: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sinkronisasi & Analisis AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kirim data HP ke Antigravity di PC',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _lastSyncTime != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Server Sync:',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11.5),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'lukmanhakim.id/api',
                          style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastSyncTime != null
                          ? 'Terakhir Disinkron: ${DateFormat('dd MMM yyyy, HH:mm').format(_lastSyncTime!)}'
                          : 'Status: Belum pernah disinkronkan ke AI',
                      style: TextStyle(
                        color: _lastSyncTime != null
                            ? const Color(0xFF34D399)
                            : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (_statusFeedback != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSuccessFeedback
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isSuccessFeedback
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _statusFeedback!,
                    style: TextStyle(
                      color: _isSuccessFeedback
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFCA5A5),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Button 1: Kirim Langsung ke AI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCloudSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Kirim Data Langsung ke AI (1-Klik)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Button 2: Salin Teks Ringkasan
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleCopySummary,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded,
                          color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Salin Teks Ringkasan Data (Clipboard)',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Button 3: Bagikan JSON
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleShareJson,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined,
                          color: Color(0xFF94A3B8), size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Bagikan Berkas File JSON Cadangan',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Panduan Singkat
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Color(0xFFEAB308), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Cara Analisis di Laptop / PC:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Tekan tombol "Kirim Data Langsung ke AI" di atas.\n'
                      '2. Di laptop/PC, ketik di chat Antigravity: "Analisa data saya".\n'
                      '3. AI akan otomatis menarik data terbaru dan membedah target SKU, sisa hari, dan estimasi gaji bersih Anda!',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
