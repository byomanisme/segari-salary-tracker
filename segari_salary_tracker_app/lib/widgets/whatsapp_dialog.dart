import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';

class WhatsAppDialog extends StatelessWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;

  const WhatsAppDialog({
    Key? key,
    required this.settings,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
  }) : super(key: key);

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  String _generateWhatsAppText() {
    int shiftSalary = 0;
    int regulerCount = 0;
    int mp3Count = 0;
    int offCount = 0;
    int trainingCount = 0;
    int totalSessions = 0;

    for (final rec in records) {
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
    for (final e in skuEntries) {
      totalSku += e.count;
    }
    final int skuBonus = settings.getBonusForSku(totalSku);
    final String severityLabel = settings.getSeverityTierLabel(totalSku);

    int totalPenalty = 0;
    for (final p in penalties) {
      totalPenalty += p.amount;
    }

    final int netSalary = (shiftSalary + skuBonus - totalPenalty).clamp(0, 999999999);

    DateTime refDate = DateTime(2026, 8, 1);
    if (records.isNotEmpty) {
      final parsed = DateTime.tryParse(records.first.date);
      if (parsed != null) refDate = parsed;
    }

    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final int lastDay = DateTime(refDate.year, refDate.month + 1, 0).day;
    final String currentMonth = monthNames[refDate.month - 1];

    final DateTime nextPayday = DateTime(refDate.year, refDate.month + 1, settings.paydayDay);
    final String nextPaydayMonthName = monthNames[nextPayday.month - 1];
    final String paydayFormatted = '${nextPayday.day.toString().padLeft(2, '0')} $nextPaydayMonthName ${nextPayday.year}';

    final buffer = StringBuffer();
    buffer.writeln('*REKAPITULASI ABSENSI & ESTIMASI GAJI SEGARI*');
    buffer.writeln('_(Sesaat Apps - Segari Salary Tracker)_');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Nama:* ${settings.name}');
    buffer.writeln('🆔 *ID DW:* ${settings.empId}');
    buffer.writeln('📅 *Periode Hitung:* 01 $currentMonth - $lastDay $currentMonth ${refDate.year}');
    buffer.writeln('🏦 *Jadwal Gajian:* Tanggal ${settings.paydayDay} ($paydayFormatted)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━\n');
    buffer.writeln('📋 *RINCIAN KEHADIRAN:*');

    for (var i = 0; i < records.length; i++) {
      final rec = records[i];
      final typeDisplay = rec.typeLabel.isNotEmpty ? rec.typeLabel : rec.type.toUpperCase();
      final nominal = _formatCurrency(rec.rate);
      final jam = (rec.shiftHours.isNotEmpty && rec.shiftHours != '-') ? ' (${rec.shiftHours})' : '';
      final notes = rec.notes.isNotEmpty ? ' - _${rec.notes}_' : '';

      buffer.writeln('${i + 1}. *${rec.date}* (${rec.dayName}): $typeDisplay$jam 👉 *$nominal*$notes');
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
        buffer.writeln('• Bonus Komisi: *Rp 0* (Kurang ${settings.severity1Target - totalSku} SKU lagi menuju Severity 1)');
      }
    }

    if (penalties.isNotEmpty) {
      buffer.writeln('\n⚠️ *POTONGAN DENDA KOMPLAIN:*');
      for (final p in penalties) {
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
      // Force launch web intent
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
    final text = _generateWhatsAppText();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 22),
          SizedBox(width: 8),
          Text(
            'Rekapitulasi WhatsApp',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Container(
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
