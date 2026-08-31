import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../services/pdf_salary_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;

  const PdfPreviewScreen({
    Key? key,
    required this.settings,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slip Gaji & Rekapitulasi PDF',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Siap Cetak / Bagikan ke WhatsApp',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        build: (format) => PdfSalaryService.generateSalarySlipPdf(
          settings: settings,
          records: records,
          penalties: penalties,
          skuEntries: skuEntries,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Slip_Gaji_Segari_${settings.name.replaceAll(' ', '_')}_Agustus_2026.pdf',
        previewPageMargin: const EdgeInsets.all(12),
        actions: const [],
      ),
    );
  }
}
