import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import 'edit_sku_commission_dialog.dart';

class SkuTargetCard extends StatelessWidget {
  final UserSettings settings;
  final List<SkuEntry> skuEntries;
  final VoidCallback onAddSku;
  final Function(SkuEntry) onDeleteSku;
  final Function(UserSettings)? onUpdateSettings;

  const SkuTargetCard({
    Key? key,
    required this.settings,
    required this.skuEntries,
    required this.onAddSku,
    required this.onDeleteSku,
    this.onUpdateSettings,
  }) : super(key: key);

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
    if (onUpdateSettings != null) {
      showDialog(
        context: context,
        builder: (_) => EditSkuCommissionDialog(
          settings: settings,
          onSave: onUpdateSettings!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSku = 0;
    for (final e in skuEntries) {
      totalSku += e.count;
    }

    final s1 = settings.severity1Target;
    final s2 = settings.severity2Target;
    final s3 = settings.severity3Target;

    final earnedBonus = settings.getBonusForSku(totalSku);
    final tierLevel = settings.getAchievedTierLevel(totalSku);
    final maxTarget = s3 > 0 ? s3 : 17500;
    final overallProgress = (totalSku / maxTarget).clamp(0.0, 1.0);

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
          // Header
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
                  if (onUpdateSettings != null) ...[
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
                    onTap: onAddSku,
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
                        _formatNumber(totalSku),
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
                onTap: onUpdateSettings != null ? () => _openEditCommission(context) : null,
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
                          if (onUpdateSettings != null) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.edit, size: 9, color: Color(0xFF94A3B8)),
                          ],
                        ],
                      ),
                      Text(
                        _formatCurrency(earnedBonus > 0 ? earnedBonus : settings.severity1Bonus),
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
            onTap: onUpdateSettings != null ? () => _openEditCommission(context) : null,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTierBadge('Sev 1: ${_formatNumber(s1)} (${_formatCurrency(settings.severity1Bonus)})', totalSku >= s1, const Color(0xFF10B981)),
                _buildTierBadge('Sev 2: ${_formatNumber(s2)} (${_formatCurrency(settings.severity2Bonus)})', totalSku >= s2, const Color(0xFF38BDF8)),
                _buildTierBadge('Sev 3: ${_formatNumber(s3)} (${_formatCurrency(settings.severity3Bonus)})', totalSku >= s3, const Color(0xFFF59E0B)),
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
                  _getDynamicStatusText(totalSku, s1, s2, s3, earnedBonus),
                  style: TextStyle(
                    color: tierLevel > 0 ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: tierLevel > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),

          // Recent SKU Entries List (Collapsible / Preview)
          if (skuEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Input Terkini', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('${skuEntries.length} catatan', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            ...skuEntries.reversed.take(2).map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${entry.date}: ${entry.notes}', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                    Row(
                      children: [
                        Text('+${_formatNumber(entry.count)} SKU', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => onDeleteSku(entry),
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
      return 'Kurang ${_formatNumber(rem)} SKU lagi untuk capai Severity 1 (+${_formatCurrency(settings.severity1Bonus)})';
    }
  }
}
