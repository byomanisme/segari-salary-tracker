import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/storage_service.dart';
import '../services/google_drive_sync_service.dart';

class BackupDialog extends StatefulWidget {
  final VoidCallback onDataRestored;

  const BackupDialog({
    Key? key,
    required this.onDataRestored,
  }) : super(key: key);

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  final StorageService _storageService = StorageService();
  final GoogleDriveSyncService _driveService = GoogleDriveSyncService();

  bool _isLoading = false;
  String _backupJson = '';
  String? _connectedEmail;
  String? _connectedName;
  DateTime? _lastBackupTime;

  final TextEditingController _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final jsonStr = await _storageService.exportFullBackupJson();
    final cachedEmail = await _driveService.getCachedEmail();
    final cachedName = await _driveService.getCachedName();
    final lastTime = await _driveService.getLastBackupTime();

    setState(() {
      _backupJson = jsonStr;
      _connectedEmail = cachedEmail;
      _connectedName = cachedName;
      _lastBackupTime = lastTime;
      _isLoading = false;
    });
  }

  // --- Official Google OAuth Gateway Sign In ---
  Future<void> _handleGoogleGatewaySignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _driveService.signInWithGoogleGateway();
      setState(() => _isLoading = false);

      if (account != null) {
        await _loadState();
        _showSuccess('Berhasil terhubung dengan Akun Google: ${account.email}');
      } else {
        _showError('Proses autentikasi Google dibatalkan.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal membuka Gateway Google: $e');
    }
  }

  // --- Backup directly to Google Drive ---
  Future<void> _handleBackupToGoogleDrive() async {
    setState(() => _isLoading = true);
    final result = await _driveService.backupToGoogleDrive();
    setState(() => _isLoading = false);

    if (result.success) {
      await _loadState();
      _showSuccess(result.message);
    } else {
      _showError(result.message);
    }
  }

  // --- Restore directly from Google Drive ---
  Future<void> _handleRestoreFromGoogleDrive() async {
    setState(() => _isLoading = true);
    final result = await _driveService.restoreFromGoogleDrive();
    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        widget.onDataRestored();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      _showError(result.message);
    }
  }

  // --- Sign Out from Google ---
  Future<void> _handleGoogleSignOut() async {
    setState(() => _isLoading = true);
    await _driveService.signOut();
    await _loadState();
    _showSuccess('Akun Google telah diputuskan.');
  }

  // --- Manual JSON Operations ---
  Future<void> _downloadJsonFile() async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(_backupJson));
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'backup_segari_salary_$dateStr.json';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      if (mounted) {
        _showSuccess('File $fileName siap disimpan ke Google Drive / HP Anda!');
      }
    } catch (e) {
      _showError('Gagal menyimpan file: $e');
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _backupJson));
    _showSuccess('Teks JSON backup berhasil disalin ke clipboard!');
  }

  Future<void> _pickAndRestoreFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';

        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        }

        if (content.isNotEmpty) {
          _restoreFromJson(content);
        } else {
          _showError('File yang dipilih kosong.');
        }
      }
    } catch (e) {
      _showError('Gagal membaca file: $e');
    }
  }

  Future<void> _restoreFromJson(String jsonContent) async {
    setState(() => _isLoading = true);
    final success = await _storageService.importFullBackupJson(jsonContent);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        widget.onDataRestored();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Seluruh data absensi & profil berhasil dipulihkan!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      _showError('Format file backup tidak valid atau rusak.');
    }
  }

  void _showPasteDialog() {
    _pasteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Tempel (Paste) Teks Backup', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tempelkan teks JSON backup yang Anda miliki di bawah ini:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pasteController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{\n  "app": "Segari Salary Tracker",\n  ...\n}',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              final text = _pasteController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _restoreFromJson(text);
              }
            },
            child: const Text('Pulihkan Data', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $msg'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $msg'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastTimeFormatted = _lastBackupTime != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_lastBackupTime!)
        : 'Belum pernah';

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_sync, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync & Google Drive',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Google OAuth 2.0 Gateway • Google Drive API',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 10),

            // SECTION 1: GOOGLE OAUTH 2.0 GATEWAY & GOOGLE DRIVE REST API
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F293D), Color(0xFF0C4A6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.g_mobiledata, color: Color(0xFF38BDF8), size: 24),
                          SizedBox(width: 4),
                          Text(
                            'GOOGLE OAUTH 2.0 GATEWAY',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      if (_connectedEmail != null)
                        InkWell(
                          onTap: _handleGoogleSignOut,
                          child: const Text('Keluar', style: TextStyle(color: Color(0xFFF87171), fontSize: 10.5, decoration: TextDecoration.underline)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_connectedEmail != null) ...[
                    // Connected with Google Account
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0284C7),
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _connectedName ?? 'Pengguna Google',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _connectedEmail!,
                                  style: const TextStyle(color: Color(0xFFBAE6FD), fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🕒 Terakhir Cadangkan ke GDrive: $lastTimeFormatted WIB',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.cloud_upload, size: 15),
                            label: const Text('Backup ke GDrive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: _isLoading ? null : _handleBackupToGoogleDrive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.cloud_download, size: 15),
                            label: const Text('Restore dr GDrive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: _isLoading ? null : _handleRestoreFromGoogleDrive,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Not connected
                    const Text(
                      'Masuk resmi dengan Akun Google untuk sinkronisasi otomatis ke Google Drive pribadi Anda:',
                      style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                          width: 16,
                          height: 16,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 20),
                        ),
                        label: const Text(
                          'Masuk dengan Akun Google',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        onPressed: _isLoading ? null : _handleGoogleGatewaySignIn,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 10),

            // SECTION 2: CADANGKAN MANUAL KE GOOGLE DRIVE / FILE .JSON
            const Text(
              'CADANGKAN MANUAL KE FILE .JSON / GDRIVE',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Unduh file `.json` dan simpan ke folder Google Drive atau catatan HP Anda:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text('Simpan File .json / GDrive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _downloadJsonFile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.folder_open, size: 15),
                    label: const Text('Pilih File', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _pickAndRestoreFile,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                    label: const Text('Salin Teks JSON', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    onPressed: _isLoading ? null : _copyToClipboard,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.paste, size: 14, color: Color(0xFF94A3B8)),
                    label: const Text('Tempel Teks JSON', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    onPressed: _isLoading ? null : _showPasteDialog,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
