import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../screens/evidence_view_screen.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AttendanceCard({
    Key? key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  Color _getBadgeColor(AttendanceRecord record) {
    switch (record.type) {
      case 'off':
        return const Color(0xFFEF4444); // 🔴 Red (OFF)
      case 'mp3':
        return const Color(0xFF8B5CF6); // 🟣 Purple (MP3H 3 Jam)
      case 'reguler_mp3':
        return const Color(0xFF10B981); // 🟢 Emerald Teal (Reguler + MP3H 11 Jam)
      case 'double_mp3':
        return const Color(0xFF3B82F6); // 🔵 Blue (Double MP3H 6 Jam)
      case 'training':
        return const Color(0xFFEAB308); // 🟡 Yellow (Training)
      case 'reguler':
        final start = record.shiftHours.trim();
        if (start.startsWith('13') || start.startsWith('14')) {
          return const Color(0xFFF97316); // 🟠 Orange (Siang/Sore 13:00-22:00 / 14:00-23:00)
        } else if (start.startsWith('03')) {
          return const Color(0xFFEAB308); // 🟡 Yellow (Subuh 03:00-12:00)
        }
        return const Color(0xFF06B6D4); // 🔷 Cyan (Pagi 04:00-13:00 / 05:00-14:00 / 09:00-18:00)
      default:
        return const Color(0xFF06B6D4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(record);
    final hasEvidence = (record.evidenceAssetPath != null && record.evidenceAssetPath!.isNotEmpty) ||
        (record.evidenceLocalFilePath != null && record.evidenceLocalFilePath!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: badgeColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.dayName.isNotEmpty ? record.dayName : '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        record.date,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      record.typeLabel.isNotEmpty ? record.typeLabel : record.type.toUpperCase(),
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.shiftHours,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(record.rate),
                      style: TextStyle(
                        color: record.rate > 0 ? const Color(0xFF34D399) : const Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.notes.isNotEmpty ? record.notes : 'Tidak ada catatan',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (hasEvidence)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EvidenceViewScreen(
                                  dateStr: record.date,
                                  assetPath: record.evidenceAssetPath,
                                  localFilePath: record.evidenceLocalFilePath,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.image, size: 12, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Bukti',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
