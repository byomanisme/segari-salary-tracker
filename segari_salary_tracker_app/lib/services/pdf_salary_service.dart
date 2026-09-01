import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';

class PdfSalaryService {
  static String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  static Future<Uint8List> generateSalarySlipPdf({
    required UserSettings settings,
    required List<AttendanceRecord> records,
    required List<ComplaintPenalty> penalties,
    required List<SkuEntry> skuEntries,
    String? cycleKey,
  }) async {
    final pdf = pw.Document();

    // Load Doodle Watermark
    pw.MemoryImage? doodleImage;
    try {
      final doodleData = await rootBundle.load('assets/images/grocery_doodle_watermark.png');
      doodleImage = pw.MemoryImage(doodleData.buffer.asUint8List());
    } catch (_) {}

    final now = DateTime.now();
    final activeKey = cycleKey ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final parts = activeKey.split('-');
    final int year = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? now.year) : now.year;
    final int month = parts.length > 1 ? (int.tryParse(parts[1]) ?? now.month) : now.month;

    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final String currentMonthName = monthNames[month - 1];

    final DateTime nextPayday = DateTime(year, month + 1, settings.paydayDay);
    final String nextPaydayMonthName = monthNames[nextPayday.month - 1];
    final String paydayFormatted = '${nextPayday.day.toString().padLeft(2, '0')} $nextPaydayMonthName ${nextPayday.year}';
    final String printDateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Filter to selected month
    final monthRecords = records.where((r) => r.date.startsWith(activeKey)).toList();
    final monthSkuEntries = skuEntries.where((e) => e.date.startsWith(activeKey)).toList();
    final monthPenalties = penalties.where((p) => p.date.startsWith(activeKey)).toList();

    // Calculations
    int shiftSalary = 0;
    int regulerCount = 0;
    int mp3Count = 0;
    int offCount = 0;
    int trainingCount = 0;
    int totalHours = 0;

    for (final r in monthRecords) {
      shiftSalary += r.rate;
      if (r.type == 'reguler') {
        regulerCount++;
        totalHours += 8;
      } else if (r.type == 'mp3') {
        mp3Count++;
        totalHours += 3;
      } else if (r.type == 'training') {
        trainingCount++;
        mp3Count++;
        totalHours += 3;
      } else if (r.type == 'reguler_mp3') {
        regulerCount++;
        mp3Count++;
        totalHours += 11;
      } else if (r.type == 'double_mp3') {
        mp3Count += 2;
        totalHours += 6;
      } else if (r.type == 'off') {
        offCount++;
      }
    }

    int totalSku = 0;
    for (final e in monthSkuEntries) {
      totalSku += e.count;
    }
    final int skuBonus = settings.getBonusForSku(totalSku);
    final String severityLabel = settings.getSeverityTierLabel(totalSku);

    int totalPenalty = 0;
    for (final p in monthPenalties) {
      totalPenalty += p.amount;
    }

    final int netSalary = (shiftSalary + skuBonus - totalPenalty).clamp(0, 999999999);

    // Primary Colors
    const primaryGreen = PdfColor.fromInt(0xFF064E3B);
    const accentGreen = PdfColor.fromInt(0xFF10B981);
    const lightBg = PdfColor.fromInt(0xFFF0FDF4);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const textDark = PdfColor.fromInt(0xFF0F172A);
    const textGray = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Card with subtle doodle art accent
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: accentGreen, width: 1.2),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SLIP GAJI & REKAPITULASI ABSENSI',
                        style: pw.TextStyle(
                          color: primaryGreen,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Sesaat Apps - Segari Salary Tracker (Official DW Report)',
                        style: const pw.TextStyle(
                          color: textGray,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  if (doodleImage != null)
                    pw.Container(
                      width: 90,
                      height: 32,
                      child: pw.Image(doodleImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: accentGreen, width: 1),
                      ),
                      child: pw.Text(
                        'STATUS: VALID (DW)',
                        style: pw.TextStyle(
                          color: primaryGreen,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Worker & Period Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGray),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Nama Pekerja', settings.name, isBold: true),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('ID Daily Worker', settings.empId),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Posisi / Divisi', 'Daily Worker (Picker / Packer)'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Periode Perhitungan', '01 $currentMonthName - $lastDayOfMonth $currentMonthName $year'),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Jadwal Gajian (Payday)', paydayFormatted, isHighlight: true),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Waktu Dicetak', printDateFormatted),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // Attendance Table
            pw.Text(
              'RINCIAN KEHADIRAN & SHIFT HARIAN',
              style: pw.TextStyle(color: primaryGreen, fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6), // No
                1: const pw.FlexColumnWidth(1.4), // Tanggal
                2: const pw.FlexColumnWidth(1.2), // Hari
                3: const pw.FlexColumnWidth(2.0), // Tipe Shift
                4: const pw.FlexColumnWidth(1.6), // Jam Kerja
                5: const pw.FlexColumnWidth(1.6), // Upah
                6: const pw.FlexColumnWidth(2.0), // Keterangan
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryGreen),
                  children: [
                    _buildTableHeader('No'),
                    _buildTableHeader('Tanggal'),
                    _buildTableHeader('Hari'),
                    _buildTableHeader('Tipe Shift'),
                    _buildTableHeader('Jam Kerja'),
                    _buildTableHeader('Upah (Rp)'),
                    _buildTableHeader('Keterangan'),
                  ],
                ),
                // Rows
                ...List.generate(monthRecords.length, (index) {
                  final rec = monthRecords[index];
                  final isEven = index % 2 == 0;
                  final isOff = rec.type == 'off';

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isOff
                          ? const PdfColor.fromInt(0xFFF1F5F9)
                          : (isEven ? const PdfColor.fromInt(0xFFFFFFFF) : const PdfColor.fromInt(0xFFF8FAFC)),
                    ),
                    children: [
                      _buildTableCell('${index + 1}', alignCenter: true),
                      _buildTableCell(rec.date),
                      _buildTableCell(rec.dayName),
                      _buildTableCell(rec.typeLabel),
                      _buildTableCell(rec.shiftHours.isNotEmpty ? rec.shiftHours : '-'),
                      _buildTableCell(
                        _formatCurrency(rec.rate),
                        isBold: !isOff,
                        textColor: isOff ? textGray : primaryGreen,
                      ),
                      _buildTableCell(rec.notes.isNotEmpty ? rec.notes : '-'),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 14),

            // Summary & Breakdown Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column: Shift Summary & SKU Progress
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF8FAFC),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGray),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RINGKASAN AKTIVITAS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: primaryGreen)),
                        pw.SizedBox(height: 4),
                        _buildSummaryItem('Shift Reguler (8 Jam)', '$regulerCount Hari (${regulerCount * 8} Jam)'),
                        _buildSummaryItem('Shift MP3H (3 Jam)', '$mp3Count Sesi (${mp3Count * 3} Jam)'),
                        _buildSummaryItem('Hari Libur (OFF)', '$offCount Hari'),
                        _buildSummaryItem('Total Jam Kerja', '$totalHours Jam'),
                        pw.SizedBox(height: 4),
                        pw.Divider(color: borderGray, height: 1),
                        pw.SizedBox(height: 4),
                        pw.Text('TARGET SKU (MULTI-TIER):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: primaryGreen)),
                        pw.SizedBox(height: 2),
                        _buildSummaryItem('Total SKU Selesai', '$totalSku SKU'),
                        _buildSummaryItem('Status Target', severityLabel),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 12),

                // Right Column: Financial Calculation Box
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: accentGreen, width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RINCIAN PENDAPATAN & POTONGAN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: primaryGreen)),
                        pw.SizedBox(height: 6),
                        _buildFinancialRow('(+) Total Upah Shift', _formatCurrency(shiftSalary)),
                        _buildFinancialRow('(+) Komisi Target SKU', _formatCurrency(skuBonus), isHighlight: skuBonus > 0),
                        if (totalPenalty > 0)
                          _buildFinancialRow('(-) Denda Komplain', '- ${_formatCurrency(totalPenalty)}', isNegative: true)
                        else
                          _buildFinancialRow('(-) Denda Komplain', 'Rp 0'),
                        pw.SizedBox(height: 6),
                        pw.Divider(color: accentGreen, height: 1.5),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL GAJI BERSIH:\n(Take Home Pay)',
                              style: pw.TextStyle(color: primaryGreen, fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                            pw.Text(
                              _formatCurrency(netSalary),
                              style: pw.TextStyle(color: primaryGreen, fontWeight: pw.FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (monthPenalties.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Catatan Denda Komplain Customer:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFDC2626))),
              pw.SizedBox(height: 2),
              ...monthPenalties.map((p) => pw.Text(
                '- ${p.date} [${p.typeLabel}]: -${_formatCurrency(p.amount)} ${p.notes.isNotEmpty ? "(${p.notes})" : ""}',
                style: const pw.TextStyle(fontSize: 8, color: textGray),
              )),
            ],

            pw.SizedBox(height: 24),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Pekerja Daily Worker,', style: const pw.TextStyle(fontSize: 9, color: textDark)),
                    pw.SizedBox(height: 36),
                    pw.Text('(${settings.name})', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('ID: ${settings.empId}', style: const pw.TextStyle(fontSize: 8, color: textGray)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mengetahui & Menyetujui,', style: const pw.TextStyle(fontSize: 9, color: textDark)),
                    pw.Text('Koordinator / Leader Segari', style: const pw.TextStyle(fontSize: 8, color: textGray)),
                    pw.SizedBox(height: 28),
                    pw.Text('( ........................................ )', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('Supervisor / Operational', style: const pw.TextStyle(fontSize: 8, color: textGray)),
                  ],
                ),
              ],
            ),

            if (doodleImage != null) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                height: 18,
                child: pw.Image(doodleImage, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(height: 4),
            ] else
              pw.SizedBox(height: 12),

            // Footer Notice
            pw.Center(
              child: pw.Text(
                'Dokumen ini dicetak otomatis melalui Sesaat Apps sebagai rincian sah perhitungan upah shift Daily Worker Segari.',
                style: const pw.TextStyle(fontSize: 7.5, color: textGray, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF64748B))),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF64748B))),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? const PdfColor.fromInt(0xFFD97706) : const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: const PdfColor.fromInt(0xFFFFFFFF), fontSize: 8.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignCenter = false, bool isBold = false, PdfColor textColor = const PdfColor.fromInt(0xFF0F172A)}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 4),
      alignment: alignCenter ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: textColor, fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF64748B))),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialRow(String label, String value, {bool isHighlight = false, bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF334155))),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: isNegative
                  ? const PdfColor.fromInt(0xFFDC2626)
                  : (isHighlight ? const PdfColor.fromInt(0xFF0284C7) : const PdfColor.fromInt(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
