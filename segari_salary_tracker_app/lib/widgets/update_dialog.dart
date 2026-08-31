import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/update_service.dart';

class UpdateAvailableDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onSnooze;
  final VoidCallback onUpdate;

  const UpdateAvailableDialog({
    Key? key,
    required this.updateInfo,
    required this.onSnooze,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Rocket Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembaruan Tersedia! 🚀',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Versi ${updateInfo.version} (${updateInfo.releaseDate})',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 12),

            const Text(
              'FITUR & PENINGKATAN TERBARU:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            // Changelog List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: updateInfo.changelog.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onSnooze();
                    },
                    child: const Text('Ingatkan Nanti', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Update Sekarang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      onUpdate();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InAppDownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final String version;

  const InAppDownloadProgressDialog({
    Key? key,
    required this.downloadUrl,
    required this.version,
  }) : super(key: key);

  @override
  State<InAppDownloadProgressDialog> createState() => _InAppDownloadProgressDialogState();
}

class _InAppDownloadProgressDialogState extends State<InAppDownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Menghubungkan ke server...';
  int _receivedBytes = 0;
  int _totalBytes = 0;
  bool _isError = false;
  String _errorMessage = '';
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _progress = 0.0;
      _status = 'Menghubungkan ke server...';
      _isError = false;
      _errorMessage = '';
    });

    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      _totalBytes = response.contentLength ?? (20 * 1024 * 1024);
      _receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/SegariSalaryTracker.apk');
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      final sink = file.openWrite();

      setState(() {
        _status = 'Mengunduh paket aplikasi APK...';
      });

      await for (final chunk in response.stream) {
        sink.add(chunk);
        _receivedBytes += chunk.length;
        if (mounted && _totalBytes > 0) {
          setState(() {
            _progress = (_receivedBytes / _totalBytes).clamp(0.0, 1.0);
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _status = 'Unduhan selesai! Membuka paket pemasang...';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      final success = await UpdateService.installApk(file.path);
      if (!success && mounted) {
        setState(() {
          _status = 'Pemasang paket sedang dijalankan di perangkat Anda.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal mengunduh: $e';
          _status = 'Terjadi kesalahan unduhan';
        });
      }
    } finally {
      _client?.close();
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.downloading_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mengunduh Sesaat Apps v${widget.version}',
                        style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _status,
                        style: TextStyle(
                          color: _isError ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _isError ? 0 : (_progress > 0 ? _progress : null),
                backgroundColor: const Color(0xFF0F172A),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                ),
                minHeight: 9,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    onPressed: _startDownload,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WhatsNewDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const WhatsNewDialog({
    Key? key,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembaruan Berhasil! 🎉',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sesaat Apps v${UpdateService.currentVersion}',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 10),

            const Text(
              'RINGKASAN FITUR TERBARU:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            // Features List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                children: UpdateService.currentWhatsNewList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: const Text('Mengerti & Mulai Kerja 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
