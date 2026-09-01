import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../services/pdf_salary_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;
  final String? initialCycleKey;

  const PdfPreviewScreen({
    Key? key,
    required this.settings,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
    this.initialCycleKey,
  }) : super(key: key);

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
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

  @override
  Widget build(BuildContext context) {
    final parts = _selectedCycleKey.split('-');
    final int year = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 2026) : 2026;
    final int month = parts.length > 1 ? (int.tryParse(parts[1]) ?? 9) : 9;
    final String currentMonthName = _monthNames[month - 1];

    final String dynamicPdfFileName =
        'Slip_Gaji_Segari_${widget.settings.name.replaceAll(' ', '_')}_${currentMonthName}_${year}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Slip Gaji & Rekapitulasi PDF',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Periode: $currentMonthName $year',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month Switcher Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _shiftMonth(-1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 4),
                        Text('Bulan Lalu', style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF10B981), size: 16),
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text('Bulan Depan', style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PDF Preview View
          Expanded(
            child: PdfPreview(
              key: ValueKey(_selectedCycleKey),
              build: (format) => PdfSalaryService.generateSalarySlipPdf(
                settings: widget.settings,
                records: widget.records,
                penalties: widget.penalties,
                skuEntries: widget.skuEntries,
                cycleKey: _selectedCycleKey,
              ),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: dynamicPdfFileName,
              previewPageMargin: const EdgeInsets.all(12),
              actions: const [],
            ),
          ),
        ],
      ),
    );
  }
}
