import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import 'edit_sku_commission_dialog.dart';

class SkuTargetCard extends StatefulWidget {
  final UserSettings settings;
  final List<SkuEntry> skuEntries;
  final VoidCallback onAddSku;
  final Function(SkuEntry) onDeleteSku;
  final Function(UserSettings)? onUpdateSettings;
  final bool isCompact;
  final VoidCallback? onOpenDetail;

  const SkuTargetCard({
    Key? key,
    required this.settings,
    required this.skuEntries,
    required this.onAddSku,
    required this.onDeleteSku,
    this.onUpdateSettings,
    this.isCompact = false,
    this.onOpenDetail,
  }) : super(key: key);

  @override
  State<SkuTargetCard> createState() => _SkuTargetCardState();
}

class _SkuTargetCardState extends State<SkuTargetCard> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterLabel = 'Bulan Ini';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to the current month full range
    _filterStartDate = DateTime(now.year, now.month, 1);
    _filterEndDate = DateTime(now.year, now.month + 1, 0);
    _filterLabel = 'Bulan Ini (${DateFormat('MMM yyyy').format(now)})';
  }

  void _showFilterDialog(BuildContext context) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Tanggal Manpower Picking',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.today, color: Color(0xFF10B981)),
                title: const Text('Hari Ini Saja', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(DateFormat('dd MMM yyyy').format(now), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                onTap: () {
                  setState(() {
                    _filterStartDate = DateTime(now.year, now.month, now.day);
                    _filterEndDate = DateTime(now.year, now.month, now.day);
                    _filterLabel = 'Hari Ini (${DateFormat('dd MMM').format(now)})';
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Color(0xFF38BDF8)),
                title: const Text('Bulan Ini Penuh (01 s/d Akhir)', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text('01 - ${DateTime(now.year, now.month + 1, 0).day} ${DateFormat('MMMM yyyy').format(now)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                onTap: () {
                  setState(() {
                    _filterStartDate = DateTime(now.year, now.month, 1);
                    _filterEndDate = DateTime(now.year, now.month + 1, 0);
                    _filterLabel = 'Bulan Ini (${DateFormat('MMM yyyy').format(now)})';
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Color(0xFFF59E0B)),
                title: const Text('Pilih Rentang Tanggal (Custom Dari - Sampai)', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(
                      start: _filterStartDate ?? DateTime(now.year, now.month, 1),
                      end: _filterEndDate ?? now,
                    ),
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF0284C7),
                          surface: Color(0xFF1E293B),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (range != null) {
                    setState(() {
                      _filterStartDate = range.start;
                      _filterEndDate = range.end;
                      _filterLabel = '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  String _formatNumber(int number) {
    final format = NumberFormat('#,###', 'id_ID');
    return format.format(number);
  }

  void _openEditCommission(BuildContext context) {
    if (widget.onUpdateSettings != null) {
      showDialog(
        context: context,
        builder: (_) => EditSkuCommissionDialog(
          settings: widget.settings,
          onSave: widget.onUpdateSettings!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Monthly Total for Target Milestones
    int totalMonthSku = 0;
    for (final e in widget.skuEntries) {
      totalMonthSku += e.count;
    }

    // 2. Filter SKU entries according to selected date range
    final filteredEntries = widget.skuEntries.where((e) {
      if (_filterStartDate == null || _filterEndDate == null) return true;
      final parsed = DateTime.tryParse(e.date);
      if (parsed == null) return true;
      final d = DateTime(parsed.year, parsed.month, parsed.day);
      final s = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
      final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day);
      return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(end) || d.isBefore(end));
    }).toList();

    int filteredSkuCount = 0;
    for (final e in filteredEntries) {
      filteredSkuCount += e.count;
    }

    final s1 = widget.settings.severity1Target;
    final s2 = widget.settings.severity2Target;
    final s3 = widget.settings.severity3Target;

    final earnedBonus = widget.settings.getBonusForSku(totalMonthSku);
    final tierLevel = widget.settings.getAchievedTierLevel(totalMonthSku);
    final maxTarget = s3 > 0 ? s3 : 17500;
    final overallProgress = (totalMonthSku / maxTarget).clamp(0.0, 1.0);

    final latestEntry = filteredEntries.isNotEmpty ? filteredEntries.last : null;
    final avgPickStr = latestEntry?.avgPicking ?? (filteredEntries.isNotEmpty ? (filteredSkuCount ~/ filteredEntries.length).toString() : '-');
    final speedStr = latestEntry?.speedTime ?? '00:00:25';

    final String dateRangeDisplay = (_filterStartDate != null && _filterEndDate != null)
        ? '${DateFormat('dd MMM yyyy').format(_filterStartDate!)} - ${DateFormat('dd MMM yyyy').format(_filterEndDate!)}'
        : 'Semua Periode';

    // 📱 Sleek & Compact View for HomeScreen
    if (widget.isCompact) {
      int? nextTarget;
      int needed = 0;
      if (totalMonthSku < s1) {
        nextTarget = s1;
        needed = s1 - totalMonthSku;
      } else if (totalMonthSku < s2) {
        nextTarget = s2;
        needed = s2 - totalMonthSku;
      } else if (totalMonthSku < s3) {
        nextTarget = s3;
        needed = s3 - totalMonthSku;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tierLevel > 0
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Bonus Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF38BDF8), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target SKU Picking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatNumber(totalMonthSku)} SKU Bulan Ini',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                // Bonus Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: earnedBonus > 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: earnedBonus > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    earnedBonus > 0 ? '+${_formatCurrency(earnedBonus)}' : 'Bonus: Rp 0',
                    style: TextStyle(
                      color: earnedBonus > 0 ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tier Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallProgress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFF0F172A),
                valueColor: AlwaysStoppedAnimation<Color>(
                  tierLevel >= 3 ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Tier status text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tierLevel > 0 ? 'Tier $tierLevel Aktif' : 'Mulai Target',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
                Text(
                  nextTarget != null
                      ? 'Kurang ${_formatNumber(needed)} SKU ke Tier ${tierLevel + 1}'
                      : '🎉 Target Maksimal Tercapai!',
                  style: TextStyle(
                    color: nextTarget != null ? const Color(0xFFCBD5E1) : const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 8),

            // Footer Quick Actions: Lihat Detail & + Input SKU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onOpenDetail,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Detail & Monitor',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onAddSku,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: Colors.white),
                        SizedBox(width: 3),
                        Text('Input SKU', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierLevel > 0
              ? const Color(0xFF10B981).withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Location & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target SKU (Multi-Tier)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Severity 1, 2, & 3 Bulanan',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (widget.onUpdateSettings != null) ...[
                    InkWell(
                      onTap: () => _openEditCommission(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune, size: 12, color: Color(0xFF38BDF8)),
                            SizedBox(width: 3),
                            Text(
                              'Ubah Komisi',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  InkWell(
                    onTap: widget.onAddSku,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Input SKU',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🖥️ Segari Monitor Dashboard Header & Date Filter
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'WH Gading Serpong - SDD • SP Gading Serpong SDD',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showFilterDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 12, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Edit Filter', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.date_range, color: Color(0xFF38BDF8), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      dateRangeDisplay,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.06), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Picking (Filter)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatNumber(filteredSkuCount)} SKU',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.white.withOpacity(0.08)),
                    Column(
                      children: [
                        const Text('AVG Picking', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          avgPickStr,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.white.withOpacity(0.08)),
                    Column(
                      children: [
                        const Text('Waktu / Barang', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          speedStr,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Total SKU Achieved & Earned Bonus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total SKU Tercapai', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatNumber(totalMonthSku),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ ${_formatNumber(maxTarget)} SKU',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onUpdateSettings != null ? () => _openEditCommission(context) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tierLevel > 0 ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tierLevel > 0 ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tierLevel > 0 ? 'Komisi Didapat' : 'Potensi Komisi',
                            style: TextStyle(
                              color: tierLevel > 0 ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
                              fontSize: 9.5,
                            ),
                          ),
                          if (widget.onUpdateSettings != null) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.edit, size: 9, color: Color(0xFF94A3B8)),
                          ],
                        ],
                      ),
                      Text(
                        _formatCurrency(earnedBonus > 0 ? earnedBonus : widget.settings.severity1Bonus),
                        style: TextStyle(
                          color: tierLevel > 0 ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Multi-Tier Milestone Indicators (Clickable to Edit)
          InkWell(
            onTap: widget.onUpdateSettings != null ? () => _openEditCommission(context) : null,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTierBadge('Sev 1: ${_formatNumber(s1)} (${_formatCurrency(widget.settings.severity1Bonus)})', totalMonthSku >= s1, const Color(0xFF10B981)),
                _buildTierBadge('Sev 2: ${_formatNumber(s2)} (${_formatCurrency(widget.settings.severity2Bonus)})', totalMonthSku >= s2, const Color(0xFF38BDF8)),
                _buildTierBadge('Sev 3: ${_formatNumber(s3)} (${_formatCurrency(widget.settings.severity3Bonus)})', totalMonthSku >= s3, const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Progress Bar with Gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 9,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(
                tierLevel == 3
                    ? const Color(0xFFF59E0B)
                    : tierLevel == 2
                        ? const Color(0xFF38BDF8)
                        : tierLevel == 1
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0284C7),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Dynamic Status Message
          Row(
            children: [
              Icon(
                tierLevel > 0 ? Icons.check_circle : Icons.info_outline,
                size: 13,
                color: tierLevel == 3
                    ? const Color(0xFFF59E0B)
                    : tierLevel == 2
                        ? const Color(0xFF38BDF8)
                        : tierLevel == 1
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _getDynamicStatusText(totalMonthSku, s1, s2, s3, earnedBonus),
                  style: TextStyle(
                    color: tierLevel > 0 ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: tierLevel > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),

          // Recent SKU Entries List (Filtered by selected date range)
          if (filteredEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Riwayat Input (${_filterLabel})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('${filteredEntries.length} catatan', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            ...filteredEntries.reversed.take(3).map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.date}: ${entry.notes}',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (entry.avgPicking != null && entry.avgPicking!.isNotEmpty)
                            Text(
                              'AVG: ${entry.avgPicking} • Speed: ${entry.speedTime ?? "00:00:25"}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '+${_formatNumber(entry.count)} SKU',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => widget.onDeleteSku(entry),
                          child: const Icon(Icons.close, size: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTierBadge(String label, bool isReached, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: isReached ? activeColor.withOpacity(0.2) : Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isReached ? activeColor : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isReached ? activeColor : const Color(0xFF64748B),
          fontSize: 9,
          fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String _getDynamicStatusText(int totalSku, int s1, int s2, int s3, int earnedBonus) {
    if (totalSku >= s3) {
      return '👑 Severity 3 Tercapai! Bonus Maksimal ${_formatCurrency(earnedBonus)} 🎉';
    } else if (totalSku >= s2) {
      final rem = s3 - totalSku;
      return '⚡ Lolos Severity 2 (+${_formatCurrency(earnedBonus)})! Sisa ${_formatNumber(rem)} SKU ke Sev 3';
    } else if (totalSku >= s1) {
      final rem = s2 - totalSku;
      return '🎉 Lolos Severity 1 (+${_formatCurrency(earnedBonus)})! Sisa ${_formatNumber(rem)} SKU ke Sev 2';
    } else {
      final rem = s1 - totalSku;
      return 'Kurang ${_formatNumber(rem)} SKU lagi untuk capai Severity 1 (+${_formatCurrency(widget.settings.severity1Bonus)})';
    }
  }
}
