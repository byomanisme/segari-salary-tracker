import 'package:flutter/material.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../widgets/sku_target_card.dart';
import '../widgets/complaint_penalty_card.dart';
import '../widgets/add_sku_dialog.dart';
import '../widgets/add_penalty_dialog.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../widgets/sku_target_card.dart';
import '../widgets/complaint_penalty_card.dart';
import '../widgets/add_sku_dialog.dart';
import '../widgets/add_penalty_dialog.dart';

class SkuPenaltyScreen extends StatefulWidget {
  final UserSettings settings;
  final List<SkuEntry> skuEntries;
  final List<ComplaintPenalty> penalties;
  final Function(SkuEntry) onAddSku;
  final Function(SkuEntry) onDeleteSku;
  final Function(ComplaintPenalty) onAddPenalty;
  final Function(ComplaintPenalty) onDeletePenalty;
  final Function(UserSettings)? onUpdateSettings;

  const SkuPenaltyScreen({
    Key? key,
    required this.settings,
    required this.skuEntries,
    required this.penalties,
    required this.onAddSku,
    required this.onDeleteSku,
    required this.onAddPenalty,
    required this.onDeletePenalty,
    this.onUpdateSettings,
  }) : super(key: key);

  @override
  State<SkuPenaltyScreen> createState() => _SkuPenaltyScreenState();
}

class _SkuPenaltyScreenState extends State<SkuPenaltyScreen> {
  String _activeCycleKey = '2026-08'; // Default cycle

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _activeCycleKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _shiftCycle(int offset) {
    final parts = _activeCycleKey.split('-');
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
      _activeCycleKey = '$year-${month.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final parts = _activeCycleKey.split('-');
    final int cycleYear = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 2026) : 2026;
    final int cycleMonth = parts.length > 1 ? (int.tryParse(parts[1]) ?? 8) : 8;
    final String currentMonthName = _monthNames[cycleMonth - 1];

    // Filter SKU entries and Penalties for the active month
    final List<SkuEntry> filteredSkuEntries = widget.skuEntries.where((e) {
      return e.date.startsWith(_activeCycleKey);
    }).toList();

    final List<ComplaintPenalty> filteredPenalties = widget.penalties.where((p) {
      return p.date.startsWith(_activeCycleKey);
    }).toList();

    int totalMonthSku = 0;
    for (final e in filteredSkuEntries) {
      totalMonthSku += e.count;
    }
    final int monthSkuBonus = widget.settings.getBonusForSku(totalMonthSku);

    int totalMonthPenalty = 0;
    for (final p in filteredPenalties) {
      totalMonthPenalty += p.amount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target SKU & Denda Komplain',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Reset Otomatis Setiap Bulan Baru • Arsip Riwayat',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Cycle Navigator (< Agustus 2026 >)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _shiftCycle(-1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, color: Color(0xFF10B981), size: 18),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Periode: $currentMonthName $cycleYear',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _shiftCycle(1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Payday notice card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siklus Bulanan Segari ($currentMonthName $cycleYear)',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target SKU & Denda dihitung per bulan (Tgl 01 s/d Akhir Bulan). Di bulan baru otomatis mulai dari 0, dan riwayat bulan sebelumnya tetap tersimpan rapi.',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Target SKU Card (Filtered by selected month)
            SkuTargetCard(
              settings: widget.settings,
              skuEntries: filteredSkuEntries,
              onUpdateSettings: widget.onUpdateSettings,
              onAddSku: () {
                showDialog(
                  context: context,
                  builder: (_) => AddSkuDialog(onSave: widget.onAddSku),
                );
              },
              onDeleteSku: widget.onDeleteSku,
            ),

            const SizedBox(height: 16),

            // Complaint Penalties Card (Filtered by selected month)
            ComplaintPenaltyCard(
              settings: widget.settings,
              penalties: filteredPenalties,
              onAddPenalty: () {
                showDialog(
                  context: context,
                  builder: (_) => AddPenaltyDialog(settings: widget.settings, onSave: widget.onAddPenalty),
                );
              },
              onDeletePenalty: widget.onDeletePenalty,
            ),

            const SizedBox(height: 16),

            // Dedicated History Logs for SKU & Denda in Selected Month
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Riwayat & Log $currentMonthName $cycleYear',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${filteredSkuEntries.length} Input SKU • ${filteredPenalties.length} Denda',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),
                  const SizedBox(height: 12),

                  // 1. SKU Logs
                  const Text(
                    '📦 Log Input SKU Harian:',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (filteredSkuEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Belum ada catatan SKU di bulan $currentMonthName $cycleYear',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...filteredSkuEntries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                e.date,
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${NumberFormat('#,###', 'id_ID').format(e.count)} SKU',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => widget.onDeleteSku(e),
                          ),
                        ],
                      ),
                    )),

                  const SizedBox(height: 14),

                  // 2. Denda Logs
                  const Text(
                    '⚠️ Log Denda Komplain:',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (filteredPenalties.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bersih! Tidak ada denda komplain di bulan $currentMonthName $cycleYear 🎉',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    ...filteredPenalties.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.date}: ${p.typeLabel}',
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                if (p.notes.isNotEmpty)
                                  Text(
                                    'Catatan: ${p.notes}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '-${_formatCurrency(p.amount)}',
                                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => widget.onDeletePenalty(p),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
