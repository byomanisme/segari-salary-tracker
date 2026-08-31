import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';

class SalaryHeroCard extends StatefulWidget {
  final List<AttendanceRecord> records;
  final List<SkuEntry> skuEntries;
  final List<ComplaintPenalty> penalties;
  final UserSettings settings;

  const SalaryHeroCard({
    Key? key,
    required this.records,
    required this.skuEntries,
    required this.penalties,
    required this.settings,
  }) : super(key: key);

  @override
  State<SalaryHeroCard> createState() => _SalaryHeroCardState();
}

class _SalaryHeroCardState extends State<SalaryHeroCard> {
  late String _activeCycleKey;

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _activeCycleKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
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

  @override
  Widget build(BuildContext context) {
    final parts = _activeCycleKey.split('-');
    final int cycleYear = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 2026) : 2026;
    final int cycleMonth = parts.length > 1 ? (int.tryParse(parts[1]) ?? 8) : 8;

    final int lastDayOfMonth = DateTime(cycleYear, cycleMonth + 1, 0).day;
    final String currentMonthName = _monthNames[cycleMonth - 1];

    // Payday is the 6th of the NEXT month
    final DateTime nextPayday = DateTime(cycleYear, cycleMonth + 1, widget.settings.paydayDay);
    final String nextPaydayMonthName = _monthNames[nextPayday.month - 1];
    final String paydayFormatted = '${nextPayday.day.toString().padLeft(2, '0')} $nextPaydayMonthName ${nextPayday.year}';

    // 1. Shift Salary for this specific cycle
    int shiftSalary = 0;
    int regulerCount = 0;
    int mp3Count = 0;
    int offCount = 0;

    for (final rec in widget.records) {
      if (rec.date.startsWith(_activeCycleKey)) {
        shiftSalary += rec.rate;
        if (rec.type == 'reguler') {
          regulerCount++;
        } else if (rec.type == 'mp3' || rec.type == 'training') {
          mp3Count++;
        } else if (rec.type == 'reguler_mp3') {
          regulerCount++;
          mp3Count++;
        } else if (rec.type == 'double_mp3') {
          mp3Count += 2;
        } else if (rec.type == 'off') {
          offCount++;
        }
      }
    }

    // 2. SKU Commission for this specific cycle with Severity 1, 2, 3 Multi-Tier
    int totalSku = 0;
    for (final e in widget.skuEntries) {
      if (e.date.startsWith(_activeCycleKey)) {
        totalSku += e.count;
      }
    }
    if (totalSku == 0 && widget.skuEntries.isNotEmpty && _activeCycleKey == '2026-08') {
      for (final e in widget.skuEntries) {
        totalSku += e.count;
      }
    }

    final int skuBonus = widget.settings.getBonusForSku(totalSku);
    final String severityLabel = widget.settings.getSeverityTierLabel(totalSku);

    // 3. Complaint Penalties for this specific cycle
    int totalPenalty = 0;
    for (final p in widget.penalties) {
      if (p.date.startsWith(_activeCycleKey)) {
        totalPenalty += p.amount;
      }
    }
    if (totalPenalty == 0 && widget.penalties.isNotEmpty && _activeCycleKey == '2026-08') {
      for (final p in widget.penalties) {
        totalPenalty += p.amount;
      }
    }

    // 4. Net Take Home Pay
    final int takeHomePay = (shiftSalary + skuBonus - totalPenalty).clamp(0, 999999999);

    final now = DateTime.now();
    final isCurrentRealMonth = (now.year == cycleYear && now.month == cycleMonth);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Watermark Outline Buah, Sayur, Daging & Ikan Segari di Seluruh Background Kotak
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.13,
                  child: Image.asset(
                    'assets/images/grocery_doodle_watermark.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Month Cycle Navigator Bar (< Agustus 2026 >)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _shiftCycle(-1),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                        ),
                      ),

                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFF6EE7B7), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Periode: 01 - $lastDayOfMonth $currentMonthName $cycleYear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (isCurrentRealMonth) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BULAN INI',
                                style: TextStyle(color: Color(0xFF064E3B), fontSize: 8.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),

                      InkWell(
                        onTap: () => _shiftCycle(1),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Payday Schedule Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          'Gajian: $paydayFormatted',
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Net Salary Amount (Take Home Pay)
                  const Text(
                    'Estimasi Gaji Bersih (Take Home Pay)',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatCurrency(takeHomePay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (skuBonus > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            severityLabel.split(' ')[0],
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.15), height: 1),
                  const SizedBox(height: 12),

                  // Salary Breakdown Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBreakdownItem('Upah Shift', _formatCurrency(shiftSalary), const Color(0xFFD1FAE5)),
                      _buildBreakdownItem(
                        'Komisi SKU',
                        skuBonus > 0 ? '+${_formatCurrency(skuBonus)}' : 'Rp 0',
                        skuBonus > 0 ? const Color(0xFFFDE68A) : const Color(0xFFD1FAE5),
                      ),
                      _buildBreakdownItem(
                        'Denda QC',
                        totalPenalty > 0 ? '-${_formatCurrency(totalPenalty)}' : 'Rp 0',
                        totalPenalty > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFD1FAE5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Shift counts
                  Row(
                    children: [
                      _buildShiftPill('$regulerCount Reguler (8j)'),
                      const SizedBox(width: 6),
                      _buildShiftPill('$mp3Count MP3H (3j)'),
                      const SizedBox(width: 6),
                      _buildShiftPill('$offCount OFF'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildShiftPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Custom Painter: Artistic Outline Watermark of Fresh Segari Fruits & Vegetables (Broccoli, Carrot, Orange, Apple, Tomato, Leaves)
class SegariFruitWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = const Color(0xFF6EE7B7).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fillSubtle = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // 🥦 1. Brokoli Segar (Top Left)
    _drawBroccoli(canvas, Offset(size.width * 0.15, size.height * 0.22), 24, strokePaint, accentPaint);

    // 🥕 2. Wortel Segari (Top Right / Center)
    _drawCarrot(canvas, Offset(size.width * 0.55, size.height * 0.18), 32, strokePaint, accentPaint);

    // 🍅 3. Tomat Segar (Left Center)
    _drawTomato(canvas, Offset(size.width * 0.10, size.height * 0.65), 26, strokePaint, accentPaint);

    // 🍊 4. Jeruk Segari Slice (Bottom Right Main)
    _drawOrangeSlice(canvas, Offset(size.width * 0.85, size.height * 0.72), 48, strokePaint, accentPaint, fillSubtle);

    // 🍎 5. Apel Segari (Center Right)
    _drawApple(canvas, Offset(size.width * 0.70, size.height * 0.38), 28, strokePaint, accentPaint);

    // 🥑 6. Alpukat / Buah Segar (Bottom Left)
    _drawAvocado(canvas, Offset(size.width * 0.32, size.height * 0.82), 25, strokePaint, accentPaint);

    // 🌿 7. Daun-daun Segar Berterbangan
    _drawLeaf(canvas, Offset(size.width * 0.40, size.height * 0.35), 18, 0.4, accentPaint);
    _drawLeaf(canvas, Offset(size.width * 0.90, size.height * 0.20), 16, -0.6, accentPaint);
    _drawLeaf(canvas, Offset(size.width * 0.58, size.height * 0.78), 20, 0.8, accentPaint);
  }

  void _drawBroccoli(Canvas canvas, Offset center, double r, Paint stroke, Paint accent) {
    // Broccoli florets (cloud-like lobes)
    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(center.dx - r * 0.4, center.dy - r * 0.2), radius: r * 0.45));
    path.addOval(Rect.fromCircle(center: Offset(center.dx + r * 0.4, center.dy - r * 0.2), radius: r * 0.45));
    path.addOval(Rect.fromCircle(center: Offset(center.dx, center.dy - r * 0.5), radius: r * 0.5));
    canvas.drawPath(path, stroke);

    // Stalk
    final stalk = Path()
      ..moveTo(center.dx - r * 0.25, center.dy + r * 0.1)
      ..lineTo(center.dx - r * 0.15, center.dy + r * 0.7)
      ..quadraticBezierTo(center.dx, center.dy + r * 0.85, center.dx + r * 0.15, center.dy + r * 0.7)
      ..lineTo(center.dx + r * 0.25, center.dy + r * 0.1);
    canvas.drawPath(stalk, accent);
  }

  void _drawCarrot(Canvas canvas, Offset center, double len, Paint stroke, Paint accent) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.5); // Angled carrot

    // Carrot Root
    final root = Path()
      ..moveTo(-len * 0.2, -len * 0.4)
      ..lineTo(len * 0.2, -len * 0.4)
      ..quadraticBezierTo(len * 0.15, len * 0.2, 0, len * 0.6)
      ..quadraticBezierTo(-len * 0.15, len * 0.2, -len * 0.2, -len * 0.4);
    canvas.drawPath(root, stroke);

    // Carrot Texture Grooves
    canvas.drawLine(Offset(-len * 0.12, -len * 0.15), Offset(len * 0.05, -len * 0.15), accent);
    canvas.drawLine(Offset(-len * 0.05, len * 0.1), Offset(len * 0.10, len * 0.1), accent);

    // Carrot Leaves on Top
    final leaves = Path()
      ..moveTo(0, -len * 0.4)
      ..quadraticBezierTo(-len * 0.2, -len * 0.7, -len * 0.1, -len * 0.85)
      ..moveTo(0, -len * 0.4)
      ..quadraticBezierTo(0, -len * 0.8, len * 0.05, -len * 0.9)
      ..moveTo(0, -len * 0.4)
      ..quadraticBezierTo(len * 0.2, -len * 0.7, len * 0.25, -len * 0.85);
    canvas.drawPath(leaves, accent);

    canvas.restore();
  }

  void _drawTomato(Canvas canvas, Offset center, double r, Paint stroke, Paint accent) {
    canvas.drawCircle(center, r, stroke);
    // Tomato calyx star leaves on top
    final calyx = Path()
      ..moveTo(center.dx, center.dy - r * 0.8)
      ..lineTo(center.dx - r * 0.4, center.dy - r * 1.1)
      ..lineTo(center.dx - r * 0.1, center.dy - r * 0.9)
      ..lineTo(center.dx, center.dy - r * 1.25) // stem
      ..lineTo(center.dx + r * 0.1, center.dy - r * 0.9)
      ..lineTo(center.dx + r * 0.4, center.dy - r * 1.1)
      ..lineTo(center.dx, center.dy - r * 0.8);
    canvas.drawPath(calyx, accent);
  }

  void _drawOrangeSlice(Canvas canvas, Offset center, double r, Paint stroke, Paint accent, Paint fill) {
    canvas.drawCircle(center, r, stroke);
    canvas.drawCircle(center, r * 0.88, fill);

    // Citrus Segments
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * 3.14159 / 180;
      final x1 = center.dx + math.cos(angle) * (r * 0.2);
      final y1 = center.dy + math.sin(angle) * (r * 0.2);
      final x2 = center.dx + math.cos(angle) * (r * 0.80);
      final y2 = center.dy + math.sin(angle) * (r * 0.80);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), accent);
    }
  }

  void _drawApple(Canvas canvas, Offset center, double r, Paint stroke, Paint accent) {
    final apple = Path()
      ..moveTo(center.dx, center.dy - r * 0.6)
      ..cubicTo(center.dx + r * 0.6, center.dy - r * 0.9, center.dx + r * 1.1, center.dy - r * 0.2, center.dx + r * 0.9, center.dy + r * 0.6)
      ..cubicTo(center.dx + r * 0.7, center.dy + r * 1.1, center.dx + r * 0.2, center.dy + r * 0.9, center.dx, center.dy + r * 0.7)
      ..cubicTo(center.dx - r * 0.2, center.dy + r * 0.9, center.dx - r * 0.7, center.dy + r * 1.1, center.dx - r * 0.9, center.dy + r * 0.6)
      ..cubicTo(center.dx - r * 1.1, center.dy - r * 0.2, center.dx - r * 0.6, center.dy - r * 0.9, center.dx, center.dy - r * 0.6);
    canvas.drawPath(apple, stroke);

    // Apple Stem & Leaf
    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 0.6)
      ..quadraticBezierTo(center.dx + 4, center.dy - r * 0.9, center.dx + 10, center.dy - r * 1.0);
    canvas.drawPath(stem, stroke);

    final leaf = Path()
      ..moveTo(center.dx + 6, center.dy - r * 0.9)
      ..quadraticBezierTo(center.dx + 20, center.dy - r * 1.1, center.dx + 22, center.dy - r * 0.8)
      ..quadraticBezierTo(center.dx + 12, center.dy - r * 0.7, center.dx + 6, center.dy - r * 0.9);
    canvas.drawPath(leaf, accent);
  }

  void _drawAvocado(Canvas canvas, Offset center, double r, Paint stroke, Paint accent) {
    // Pear-shaped avocado outline
    final avo = Path()
      ..moveTo(center.dx, center.dy - r * 0.9)
      ..cubicTo(center.dx + r * 0.5, center.dy - r * 0.9, center.dx + r * 0.8, center.dy - r * 0.2, center.dx + r * 0.8, center.dy + r * 0.4)
      ..cubicTo(center.dx + r * 0.8, center.dy + r * 0.9, center.dx - r * 0.8, center.dy + r * 0.9, center.dx - r * 0.8, center.dy + r * 0.4)
      ..cubicTo(center.dx - r * 0.8, center.dy - r * 0.2, center.dx - r * 0.5, center.dy - r * 0.9, center.dx, center.dy - r * 0.9);
    canvas.drawPath(avo, stroke);

    // Seed circle
    canvas.drawCircle(Offset(center.dx, center.dy + r * 0.35), r * 0.35, accent);
  }

  void _drawLeaf(Canvas canvas, Offset center, double len, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-len * 0.5, 0)
      ..quadraticBezierTo(0, -len * 0.35, len * 0.5, 0)
      ..quadraticBezierTo(0, len * 0.35, -len * 0.5, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
