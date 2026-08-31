import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/penalty_model.dart';
import '../models/user_settings.dart';

class ComplaintPenaltyCard extends StatelessWidget {
  final UserSettings settings;
  final List<ComplaintPenalty> penalties;
  final VoidCallback onAddPenalty;
  final Function(ComplaintPenalty) onDeletePenalty;

  const ComplaintPenaltyCard({
    Key? key,
    required this.settings,
    required this.penalties,
    required this.onAddPenalty,
    required this.onDeletePenalty,
  }) : super(key: key);

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
    int totalPenalty = 0;
    for (final p in penalties) {
      totalPenalty += p.amount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: totalPenalty > 0
              ? const Color(0xFFEF4444).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.report_problem_outlined, color: Color(0xFFEF4444), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Denda Komplain Customer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Potongan Mutu & QC Segari',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: onAddPenalty,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'Catat Denda',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Penalty Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL POTONGAN DENDA',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Mengurangi Estimasi Gaji Bersih',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                    ),
                  ],
                ),
                Text(
                  '- ${_formatCurrency(totalPenalty)}',
                  style: TextStyle(
                    color: totalPenalty > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Standard Penalty Rules Info
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildRuleBadge('Barang Kurang: Rp 10rb'),
              _buildRuleBadge('SKU Busuk: Rp 50rb'),
            ],
          ),

          if (penalties.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Rincian Komplain Tercatat:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: penalties.length,
              itemBuilder: (context, index) {
                final item = penalties.reversed.toList()[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
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
                              '${item.typeLabel} • ${item.date}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.notes.isNotEmpty)
                              Text(
                                item.notes,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '- ${_formatCurrency(item.amount)}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => onDeletePenalty(item),
                            child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              '✨ Tidak ada catatan denda komplain. Kerja bagus!',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
      ),
    );
  }
}
