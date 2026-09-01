import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';

class WhatsAppDialog extends StatefulWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;
  final String? initialCycleKey;

  const WhatsAppDialog({
    Key? key,
    required this.settings,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
    this.initialCycleKey,
  }) : super(key: key);

  @override
  State<WhatsAppDialog> createState() => _WhatsAppDialogState();
}

class _WhatsAppDialogState extends State<WhatsAppDialog> {
  late String _selectedCycleKey;

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedCycleKey = widget.initialCycleKey ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _shiftMonth(int offset) {
    final parts = _selectedCycleKey.split('-');
    if (parts.length < 2) return;
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    month += offset;
    if (month > 12) {
      month = 1;
      year += 1;
    } else if (month < 1) {
      month = 12;
      year -= 1;
    }

    setState(() {
      _selectedCycleKey = '$year-${month.toString().padLeft(2, '0')}';
    });
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  String _generateWhatsAppText() {
    final parts = _selectedCycleKey.split('-');
    final int year = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 2026) : 2026;
    final int month = parts.length > 1 ? (int.tryParse(parts[1]) ?? 9) : 9;

    final String currentMonthName = _monthNames[month - 1];
    final int lastDay = DateTime(year, month + 1, 0).day;

    final DateTime nextPayday = DateTime(year, month + 1, widget.settings.paydayDay);
    final String nextPaydayMonthName = _monthNames[nextPayday.month - 1];
    final String paydayFormatted = '${nextPayday.day.toString().padLeft(2, '0')} $nextPaydayMonthName ${nextPayday.year}';

    // 1. Filter data by selected month
    final monthRecords = widget.records.where((r) => r.date.startsWith(_selectedCycleKey)).toList();
    final monthSkuEntries = widget.skuEntries.where((e) => e.date.startsWith(_selectedCycleKey)).toList();
    final monthPenalties = widget.penalties.where((p) => p.date.startsWith(_selectedCycleKey)).toList();

    int shiftSalary = 0;
    int regulerCount = 0;
    int mp3Count = 0;
    int offCount = 0;
    int trainingCount = 0;
    int totalSessions = 0;

    for (final rec in monthRecords) {
      shiftSalary += rec.rate;
      if (rec.type == 'reguler') {
        regulerCount++;
        totalSessions++;
      } else if (rec.type == 'mp3') {
        mp3Count++;
        totalSessions++;
      } else if (rec.type == 'training') {
        trainingCount++;
        mp3Count++;
        totalSessions++;
      } else if (rec.type == 'reguler_mp3') {
        regulerCount++;
        mp3Count++;
        totalSessions += 2;
      } else if (rec.type == 'double_mp3') {
        mp3Count += 2;
        totalSessions += 2;
      } else if (rec.type == 'off') {
        offCount++;
      }
    }

    int totalSku = 0;
    for (final e in monthSkuEntries) {
      totalSku += e.count;
    }
    final int skuBonus = widget.settings.getBonusForSku(totalSku);
    final String severityLabel = widget.settings.getSeverityTierLabel(totalSku);

    int totalPenalty = 0;
    for (final p in monthPenalties) {
      totalPenalty += p.amount;
    }

    final int netSalary = (shiftSalary + skuBonus - totalPenalty).clamp(0, 999999999);

    final buffer = StringBuffer();
    buffer.writeln('*REKAPITULASI ABSENSI & ESTIMASI GAJI SEGARI*');
    buffer.writeln('_(Sesaat Apps - Segari Salary Tracker)_');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Nama:* ${widget.settings.name}');
    buffer.writeln('🆔 *ID DW:* ${widget.settings.empId}');
    buffer.writeln('📅 *Periode Hitung:* 01 $currentMonthName - $lastDay $currentMonthName $year');
    buffer.writeln('🏦 *Jadwal Gajian:* Tanggal ${widget.settings.paydayDay} ($paydayFormatted)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━\n');
    buffer.writeln('📋 *RINCIAN KEHADIRAN:*');

    if (monthRecords.isEmpty) {
      buffer.writeln('_(Belum ada data kehadiran pada bulan $currentMonthName $year)_\n');
    } else {
      for (var i = 0; i < monthRecords.length; i++) {
        final rec = monthRecords[i];
        final typeDisplay = rec.typeLabel.isNotEmpty ? rec.typeLabel : rec.type.toUpperCase();
        final nominal = _formatCurrency(rec.rate);
        final jam = (rec.shiftHours.isNotEmpty && rec.shiftHours != '-') ? ' (${rec.shiftHours})' : '';
        final notes = rec.notes.isNotEmpty ? ' - _${rec.notes}_' : '';

        buffer.writeln('${i + 1}. *${rec.date}* (${rec.dayName}): $typeDisplay$jam 👉 *$nominal*$notes');
      }
    }

    buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 *RINGKASAN SHIFT & AKTIVITAS:*');
    if (trainingCount > 0) buffer.writeln('• Training (MP3H): *$trainingCount hari*');
    buffer.writeln('• Shift Reguler (8 Jam): *$regulerCount hari*');
    buffer.writeln('• Shift MP3H (3 Jam): *$mp3Count sesi*');
    buffer.writeln('• Libur (OFF): *$offCount hari*');
    buffer.writeln('• Total Sesi Kerja: *$totalSessions sesi*');
    buffer.writeln('• Total Upah Shift: *${_formatCurrency(shiftSalary)}*');

    if (totalSku > 0) {
      buffer.writeln('\n📦 *PENCAPAIAN TARGET SKU (MULTI-TIER):*');
      buffer.writeln('• Total SKU: *$totalSku SKU*');
      buffer.writeln('• Status Target: *$severityLabel*');
      if (skuBonus > 0) {
        buffer.writeln('• Bonus Komisi: *+ ${_formatCurrency(skuBonus)}* (Tercapai 🎉)');
      } else {
        buffer.writeln('• Bonus Komisi: *Rp 0* (Kurang ${widget.settings.severity1Target - totalSku} SKU lagi menuju Severity 1)');
      }
    }

    if (monthPenalties.isNotEmpty) {
      buffer.writeln('\n⚠️ *POTONGAN DENDA KOMPLAIN:*');
      for (final p in monthPenalties) {
        buffer.writeln('• ${p.date} - ${p.typeLabel}: *- ${_formatCurrency(p.amount)}* ${p.notes.isNotEmpty ? "(${p.notes})" : ""}');
      }
      buffer.writeln('• Total Denda: *- ${_formatCurrency(totalPenalty)}*');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *ESTIMASI GAJI BERSIH (TAKE HOME PAY):*');
    buffer.writeln('👉 *${_formatCurrency(netSalary)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Dibuat otomatis via Sesaat Apps (Segari Salary Tracker)_');

    return buffer.toString();
  }

  Future<void> _launchWhatsApp(String text, BuildContext context) async {
    // 1. Copy to clipboard as auto-backup
    await Clipboard.setData(ClipboardData(text: text));

    final encoded = Uri.encodeComponent(text);
    final List<Uri> candidateUris = [
      Uri.parse('whatsapp://send?text=$encoded'),
      Uri.parse('https://api.whatsapp.com/send?text=$encoded'),
      Uri.parse('https://wa.me/?text=$encoded'),
    ];

    bool launched = false;
    for (final u in candidateUris) {
      try {
        if (await canLaunchUrl(u)) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (_) {}
    }

    if (!launched) {
      try {
        await launchUrl(
          Uri.parse('https://api.whatsapp.com/send?text=$encoded'),
          mode: LaunchMode.externalApplication,
        );
        launched = true;
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched
                ? '✅ Membuka WhatsApp... (Teks juga telah otomatis disalin)'
                : '📋 Teks rekap berhasil disalin ke Clipboard! Silakan paste di WhatsApp.',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = _selectedCycleKey.split('-');
    final int year = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 2026) : 2026;
    final int month = parts.length > 1 ? (int.tryParse(parts[1]) ?? 9) : 9;
    final String currentMonthName = _monthNames[month - 1];

    final text = _generateWhatsAppText();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 22),
              SizedBox(width: 8),
              Text(
                'Rekapitulasi WhatsApp',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month Selector Bar (< September 2026 >)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _shiftMonth(-1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.chevron_left, color: Color(0xFF25D366), size: 18),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF25D366), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '$currentMonthName $year',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _shiftMonth(1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.chevron_right, color: Color(0xFF25D366), size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Preview Text Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Salin Teks'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Teks rekap berhasil disalin ke clipboard')),
            );
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Kirim ke WA'),
          onPressed: () {
            Navigator.pop(context);
            _launchWhatsApp(text, context);
          },
        ),
      ],
    );
  }
}
