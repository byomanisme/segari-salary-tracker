import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/update_service.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final UserSettings settings;
  final Function(UserSettings) onSave;
  final VoidCallback onResetData;

  const SettingsScreen({
    Key? key,
    required this.settings,
    required this.onSave,
    required this.onResetData,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _empIdController;
  late TextEditingController _regulerRateController;
  late TextEditingController _mp3RateController;

  // Severity 1, 2, 3 Controllers
  late TextEditingController _s1TargetController;
  late TextEditingController _s1BonusController;
  late TextEditingController _s2TargetController;
  late TextEditingController _s2BonusController;
  late TextEditingController _s3TargetController;
  late TextEditingController _s3BonusController;

  late TextEditingController _paydayDayController;
  late TextEditingController _penaltyLessController;
  late TextEditingController _penaltyRottenController;

  bool _isCheckingUpdate = false;
  final _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.name);
    _empIdController = TextEditingController(text: widget.settings.empId);
    _regulerRateController = TextEditingController(text: widget.settings.regulerRate.toString());
    _mp3RateController = TextEditingController(text: widget.settings.mp3Rate.toString());

    _s1TargetController = TextEditingController(text: widget.settings.severity1Target.toString());
    _s1BonusController = TextEditingController(text: widget.settings.severity1Bonus.toString());
    _s2TargetController = TextEditingController(text: widget.settings.severity2Target.toString());
    _s2BonusController = TextEditingController(text: widget.settings.severity2Bonus.toString());
    _s3TargetController = TextEditingController(text: widget.settings.severity3Target.toString());
    _s3BonusController = TextEditingController(text: widget.settings.severity3Bonus.toString());

    _paydayDayController = TextEditingController(text: widget.settings.paydayDay.toString());
    _penaltyLessController = TextEditingController(text: widget.settings.penaltyLessItem.toString());
    _penaltyRottenController = TextEditingController(text: widget.settings.penaltyRottenSku.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _empIdController.dispose();
    _regulerRateController.dispose();
    _mp3RateController.dispose();
    _s1TargetController.dispose();
    _s1BonusController.dispose();
    _s2TargetController.dispose();
    _s2BonusController.dispose();
    _s3TargetController.dispose();
    _s3BonusController.dispose();
    _paydayDayController.dispose();
    _penaltyLessController.dispose();
    _penaltyRottenController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.settings.copyWith(
      name: _nameController.text.trim(),
      empId: _empIdController.text.trim(),
      regulerRate: int.tryParse(_regulerRateController.text) ?? 120000,
      mp3Rate: int.tryParse(_mp3RateController.text) ?? 50000,
      severity1Target: int.tryParse(_s1TargetController.text) ?? 13500,
      severity1Bonus: int.tryParse(_s1BonusController.text) ?? 400000,
      severity2Target: int.tryParse(_s2TargetController.text) ?? 15500,
      severity2Bonus: int.tryParse(_s2BonusController.text) ?? 600000,
      severity3Target: int.tryParse(_s3TargetController.text) ?? 17500,
      severity3Bonus: int.tryParse(_s3BonusController.text) ?? 800000,
      paydayDay: int.tryParse(_paydayDayController.text) ?? 6,
      penaltyLessItem: int.tryParse(_penaltyLessController.text) ?? 10000,
      penaltyRottenSku: int.tryParse(_penaltyRottenController.text) ?? 50000,
    );

    widget.onSave(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Pengaturan profil, tarif upah & Severity SKU berhasil disimpan!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _manualCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    final updateInfo = await _updateService.checkForUpdate(isManualCheck: true);
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (updateInfo != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateAvailableDialog(
          updateInfo: updateInfo,
          onSnooze: () => _updateService.snoozeUpdateForTomorrow(),
          onUpdate: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => InAppDownloadProgressDialog(
                downloadUrl: updateInfo.downloadUrl,
                version: updateInfo.version,
              ),
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text('Versi Aplikasi', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aplikasi Anda menggunakan versi terbaru:\nv${UpdateService.currentVersion} (Build ${UpdateService.currentBuildNumber})',
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Semua fitur mutakhir (Skin Maskot Segari 🎭, Warna Shift Excel 🎨, & Target SKU Multi-Tier 🎯) telah aktif.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => WhatsNewDialog(onDismiss: () {}),
                );
              },
              child: const Text('Lihat Fitur Baru', style: TextStyle(color: Color(0xFF38BDF8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pengaturan Akun & Aturan Segari',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil Section
              const Text(
                'PROFIL PEKERJA',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              const Text(
                'Nama Pekerja (Daily Worker)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 14),

              const Text(
                'ID Daily Worker (DW)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _empIdController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 14),

              // Standar Upah Shift
              const Text(
                'STANDAR TARIF UPAH SHIFT',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shift Reguler 8 Jam (Rp)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _regulerRateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shift MP3H 3 Jam (Man Power 3 Hours)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _mp3RateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 14),

              // Target SKU Multi-Tier (Severity 1, 2, 3)
              const Text(
                'TARGET SKU & KOMISI BULANAN (SEVERITY 1, 2, 3)',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              const Text(
                'Atur target jumlah SKU dan komisi bonus untuk masing-masing level Severity.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Severity 1
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.looks_one, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 6),
                        Text('Severity 1 (Target Utama)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _s1TargetController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration(suffixText: 'SKU'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _s1BonusController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(suffixText: 'Rp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Severity 2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.looks_two, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 6),
                        Text('Severity 2 (Target Menengah)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _s2TargetController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration(suffixText: 'SKU'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _s2BonusController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(suffixText: 'Rp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Severity 3
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.looks_3, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 6),
                        Text('Severity 3 (Target Maksimal 🔥)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _s3TargetController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration(suffixText: 'SKU'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _s3BonusController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(suffixText: 'Rp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 14),

              // Standar Denda Komplain & Gajian
              const Text(
                'STANDAR DENDA KOMPLAIN & GAJIAN',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Barang Kurang (Rp)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _penaltyLessController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SKU Busuk/Rusak (Rp)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _penaltyRottenController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'Tanggal Gajian Setiap Bulan (Default: Tanggal 6)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _paydayDayController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14, fontWeight: FontWeight.bold),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                decoration: _inputDecoration(suffixText: 'Setiap Bulan'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF064E3B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _save,
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 16),

              // Pembaruan Aplikasi (App Update Section)
              const Text(
                'PEMBARUAN APLIKASI (APP UPDATE)',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.system_update, color: Color(0xFF38BDF8), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sesaat Apps v${UpdateService.currentVersion} (Build ${UpdateService.currentBuildNumber})',
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Status: Versi Terpasang Paling Mutakhir',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                            icon: const Icon(Icons.list_alt, size: 15),
                            label: const Text('Rincian Fitur Baru', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => WhatsNewDialog(onDismiss: () {}),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                            icon: _isCheckingUpdate
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.refresh, size: 15),
                            label: const Text('Cek Pembaruan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 16),

              // Backup & Restore Section (Akun Gmail)
              const Text(
                'SINKRONISASI AKUN GMAIL & CLOUD BACKUP',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
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
                    const Row(
                      children: [
                        Icon(Icons.cloud_sync, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cloud Backup Akun Gmail',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hubungkan akun Gmail Anda agar seluruh riwayat absensi, target SKU, dan catatan denda tersinkronisasi otomatis. Saat ganti HP baru, cukup pulihkan dari Gmail secara instan tanpa file!',
                      style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11.5),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(Icons.account_circle, size: 17),
                        label: const Text('Buka Menu Sinkronisasi Gmail & Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BackupDialog(
                              onDataRestored: () {
                                widget.onResetData();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? suffixText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
    );
  }
}
