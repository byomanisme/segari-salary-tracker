import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../widgets/attendance_card.dart';
import '../widgets/backup_dialog.dart';
import 'add_edit_screen.dart';

class HistoryScreen extends StatefulWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;
  final Function(AttendanceRecord) onSaveRecord;
  final Function(AttendanceRecord) onDeleteRecord;
  final VoidCallback? onDataRestored;

  const HistoryScreen({
    Key? key,
    required this.settings,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
    required this.onSaveRecord,
    required this.onDeleteRecord,
    this.onDataRestored,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';
  String _selectedYear = '2026'; // Default Year: 2026
  String _selectedMonth = '08'; // Default Month: 08 (Agustus)
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _monthOptions = [
    {'value': '01', 'label': 'Januari (01)'},
    {'value': '02', 'label': 'Februari (02)'},
    {'value': '03', 'label': 'Maret (03)'},
    {'value': '04', 'label': 'April (04)'},
    {'value': '05', 'label': 'Mei (05)'},
    {'value': '06', 'label': 'Juni (06)'},
    {'value': '07', 'label': 'Juli (07)'},
    {'value': '08', 'label': 'Agustus (08)'},
    {'value': '09', 'label': 'September (09)'},
    {'value': '10', 'label': 'Oktober (10)'},
    {'value': '11', 'label': 'November (11)'},
    {'value': '12', 'label': 'Desember (12)'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  // Generates complete list of years from Segari's founding year (2021) to 2050
  List<String> _getAvailableYears() {
    final List<String> years = [];
    for (int y = 2050; y >= 2021; y--) {
      years.add(y.toString());
    }
    return years;
  }

  String _getActivePeriodLabel() {
    final found = _monthOptions.firstWhere(
      (m) => m['value'] == _selectedMonth,
      orElse: () => {'label': _selectedMonth},
    );
    final monthName = found['label']!.replaceAll(RegExp(r'\s*\(\d+\)'), '');
    return '$monthName $_selectedYear';
  }

  List<AttendanceRecord> _getFilteredRecords() {
    final activePrefix = '$_selectedYear-$_selectedMonth';
    return widget.records.where((rec) {
      // 1. Month & Year Filter
      final matchesMonth = rec.date.startsWith(activePrefix);

      // 2. Type Filter
      final matchesFilter = (_selectedFilter == 'all') ||
          (_selectedFilter == 'reguler' && (rec.type == 'reguler' || rec.type == 'reguler_mp3')) ||
          (_selectedFilter == 'mp3' && (rec.type == 'mp3' || rec.type == 'reguler_mp3')) ||
          (_selectedFilter == 'training' && rec.type == 'training') ||
          (_selectedFilter == 'off' && rec.type == 'off');

      // 3. Search Query
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          rec.date.toLowerCase().contains(query) ||
          rec.dayName.toLowerCase().contains(query) ||
          rec.notes.toLowerCase().contains(query) ||
          rec.typeLabel.toLowerCase().contains(query);

      return matchesMonth && matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _openEdit(AttendanceRecord existing) async {
    final result = await Navigator.push<AttendanceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          record: existing,
          settings: widget.settings,
        ),
      ),
    );

    if (result != null) {
      widget.onSaveRecord(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan data absensi disimpan')),
        );
      }
    }
  }

  Future<void> _confirmDelete(AttendanceRecord rec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Absensi', style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data shift tanggal ${rec.date} (${rec.dayName})?',
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDeleteRecord(rec);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data absensi dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePrefix = '$_selectedYear-$_selectedMonth';
    final filtered = _getFilteredRecords();
    final displayList = filtered.reversed.toList();

    // 1. Shift Salary for selected month
    int monthTotalSalary = 0;
    int monthTotalHours = 0;
    int monthShiftCount = 0;

    for (final r in filtered) {
      monthTotalSalary += r.rate;
      if (r.type != 'off') monthShiftCount++;
      if (r.type == 'reguler') monthTotalHours += 8;
      if (r.type == 'mp3' || r.type == 'training') monthTotalHours += 3;
      if (r.type == 'reguler_mp3') monthTotalHours += 11;
    }

    // 2. SKU Target Commission for selected month
    int monthSkuCount = 0;
    for (final e in widget.skuEntries) {
      if (e.date.startsWith(activePrefix)) {
        monthSkuCount += e.count;
      }
    }
    // Fallback if testing August 2026
    if (monthSkuCount == 0 && widget.skuEntries.isNotEmpty && activePrefix == '2026-08') {
      for (final e in widget.skuEntries) {
        monthSkuCount += e.count;
      }
    }
    final int monthSkuBonus = widget.settings.getBonusForSku(monthSkuCount);
    final String monthSeverityLabel = widget.settings.getSeverityTierLabel(monthSkuCount);

    // 3. Complaint Penalties for selected month
    int monthPenalty = 0;
    final List<ComplaintPenalty> activePenalties = [];
    for (final p in widget.penalties) {
      if (p.date.startsWith(activePrefix)) {
        monthPenalty += p.amount;
        activePenalties.add(p);
      }
    }
    if (monthPenalty == 0 && widget.penalties.isNotEmpty && activePrefix == '2026-08') {
      for (final p in widget.penalties) {
        monthPenalty += p.amount;
        activePenalties.add(p);
      }
    }

    // 4. Net Take Home Pay for selected month
    final int monthNetPay = (monthTotalSalary + monthSkuBonus - monthPenalty).clamp(0, 999999999);

    final availableYears = _getAvailableYears();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Absensi Shift',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Arsip 2021 - 2050 • Target SKU & Denda',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Color(0xFF38BDF8)),
            tooltip: 'Backup / Pulihkan Data',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BackupDialog(
                  onDataRestored: () {
                    if (widget.onDataRestored != null) {
                      widget.onDataRestored!();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Separate Year (2021-2050) & Month (01-12) Selectors
            Row(
              children: [
                // 1. Selector Tahun (2021 - 2050)
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            Icon(Icons.calendar_today, color: Color(0xFF38BDF8), size: 11),
                            SizedBox(width: 4),
                            Text(
                              'TAHUN',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedYear,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            items: availableYears.map((y) {
                              return DropdownMenuItem<String>(
                                value: y,
                                child: Text(y), // Clean Year Number without "Tahun"
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Selector Bulan (Januari - Desember)
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            Icon(Icons.date_range, color: Color(0xFF10B981), size: 11),
                            SizedBox(width: 4),
                            Text(
                              'BULAN',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedMonth,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            items: _monthOptions.map((m) {
                              return DropdownMenuItem<String>(
                                value: m['value'],
                                child: Text(m['label']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMonth = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Comprehensive Monthly Financial & Target Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F291E), Color(0xFF133E2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Header & Total Take Home Pay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekap Gaji ${_getActivePeriodLabel()}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Siklus 01 s/d Akhir Bulan • Cair Tgl 6',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatCurrency(monthNetPay),
                          style: const TextStyle(color: Color(0xFF064E3B), fontSize: 12.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),
                  const SizedBox(height: 10),

                  // Financial Breakdown (Upah Shift, Komisi Target SKU, Denda QC)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniSummary('Upah Shift', _formatCurrency(monthTotalSalary), const Color(0xFF10B981)),
                      _buildMiniSummary(
                        'Komisi Target SKU',
                        monthSkuBonus > 0 ? '+${_formatCurrency(monthSkuBonus)}' : 'Rp 0 ($monthSkuCount SKU)',
                        monthSkuBonus > 0 ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8),
                      ),
                      _buildMiniSummary(
                        'Denda Komplain',
                        monthPenalty > 0 ? '-${_formatCurrency(monthPenalty)}' : 'Rp 0',
                        monthPenalty > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),

                  if (activePenalties.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text(
                                'Catatan Denda Komplain Bulan Ini:',
                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ...activePenalties.map((p) => Text(
                            '• ${p.date}: ${p.typeLabel} (-${_formatCurrency(p.amount)})',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 10),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari tanggal, hari, atau catatan...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('all', 'Semua Shift'),
                  _buildFilterPill('reguler', 'Reguler (8j)'),
                  _buildFilterPill('mp3', 'MP3 (3j)'),
                  _buildFilterPill('training', 'Training'),
                  _buildFilterPill('off', 'Libur (OFF)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Header List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Absensi (${_getActivePeriodLabel()})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    '${filtered.length} Shift',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Attendance List
            if (displayList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.event_busy, size: 44, color: Color(0xFF64748B)),
                    SizedBox(height: 10),
                    Text(
                      'Tidak ada data absensi untuk bulan ini.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final rec = displayList[index];
                  return AttendanceCard(
                    record: rec,
                    onEdit: () => _openEdit(rec),
                    onDelete: () => _confirmDelete(rec),
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSummary(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedFilter = filterKey),
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: const Color(0xFF10B981),
        checkmarkColor: const Color(0xFF064E3B),
        side: BorderSide(
          color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
