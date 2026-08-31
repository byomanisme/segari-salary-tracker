import 'package:flutter/material.dart';

class ShiftTimePickerDialog extends StatefulWidget {
  final String initialHours;

  const ShiftTimePickerDialog({
    Key? key,
    required this.initialHours,
  }) : super(key: key);

  @override
  State<ShiftTimePickerDialog> createState() => _ShiftTimePickerDialogState();
}

class _ShiftTimePickerDialogState extends State<ShiftTimePickerDialog> {
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);
  bool _isMp3Extra = false;
  TimeOfDay _extraStartTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _extraEndTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _parseInitialHours();
  }

  void _parseInitialHours() {
    final raw = widget.initialHours.trim();
    if (raw.contains('&')) {
      _isMp3Extra = true;
      final parts = raw.split('&');
      if (parts.length >= 2) {
        _parseStartEnd(parts[0].trim(), (s, e) {
          _startTime = s;
          _endTime = e;
        });
        _parseStartEnd(parts[1].trim(), (s, e) {
          _extraStartTime = s;
          _extraEndTime = e;
        });
      }
    } else if (raw.contains('-')) {
      _parseStartEnd(raw, (s, e) {
        _startTime = s;
        _endTime = e;
      });
    }
  }

  void _parseStartEnd(String text, Function(TimeOfDay, TimeOfDay) onParsed) {
    try {
      final parts = text.split('-');
      if (parts.length == 2) {
        final sParts = parts[0].trim().split(':');
        final eParts = parts[1].trim().split(':');
        if (sParts.length == 2 && eParts.length == 2) {
          final s = TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));
          final e = TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));
          onParsed(s, e);
        }
      }
    } catch (_) {}
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTimeDial({
    required BuildContext context,
    required TimeOfDay initialTime,
    required String title,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
      confirmText: 'PILIH JAM',
      cancelText: 'BATAL',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
              secondary: Color(0xFF38BDF8),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E293B),
              hourMinuteColor: const Color(0xFF0F172A),
              hourMinuteTextColor: const Color(0xFF10B981),
              dialBackgroundColor: const Color(0xFF0F172A),
              dialHandColor: const Color(0xFF10B981),
              dialTextColor: Colors.white,
              entryModeIconColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  void _applyPreset(String startStr, String endStr, {bool extra = false, String extraStart = '', String extraEnd = ''}) {
    _parseStartEnd('$startStr - $endStr', (s, e) {
      setState(() {
        _startTime = s;
        _endTime = e;
        _isMp3Extra = extra;
        if (extra) {
          _parseStartEnd('$extraStart - $extraEnd', (es, ee) {
            _extraStartTime = es;
            _extraEndTime = ee;
          });
        }
      });
    });
  }

  String _calculateFormattedResult() {
    final mainStr = '${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
    if (_isMp3Extra) {
      return '$mainStr & ${_formatTime(_extraStartTime)} - ${_formatTime(_extraEndTime)}';
    }
    return mainStr;
  }

  double _calculateTotalHours() {
    double diff(TimeOfDay s, TimeOfDay e) {
      double startMins = s.hour * 60.0 + s.minute;
      double endMins = e.hour * 60.0 + e.minute;
      if (endMins < startMins) endMins += 24 * 60; // Next day
      return (endMins - startMins) / 60.0;
    }

    double total = diff(_startTime, _endTime);
    if (_isMp3Extra) {
      total += diff(_extraStartTime, _extraEndTime);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _calculateTotalHours();
    final resultString = _calculateFormattedResult();

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time_filled, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Jam Kerja',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Putar Lingkaran Jam / Pilih Preset Segari',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Live Time Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B20), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text(
                    'JADWAL JAM TERPILIH',
                    style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resultString,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⏱️ Total Durasi: ${totalHours.toStringAsFixed(totalHours.truncateToDouble() == totalHours ? 0 : 1)} Jam Kerja',
                      style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Jam Utama (Mulai & Selesai)
            const Text(
              'PUTAR JAM KERJA UTAMA',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    label: 'Jam Mulai',
                    time: _startTime,
                    icon: Icons.play_circle_outline,
                    color: const Color(0xFF10B981),
                    onTap: () => _pickTimeDial(
                      context: context,
                      initialTime: _startTime,
                      title: 'PILIH JAM MULAI (PUTAR JARUM JAM)',
                      onSelected: (t) => _startTime = t,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Color(0xFF64748B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeButton(
                    label: 'Jam Selesai',
                    time: _endTime,
                    icon: Icons.stop_circle_outlined,
                    color: const Color(0xFF38BDF8),
                    onTap: () => _pickTimeDial(
                      context: context,
                      initialTime: _endTime,
                      title: 'PILIH JAM SELESAI (PUTAR JARUM JAM)',
                      onSelected: (t) => _endTime = t,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Toggle Tambahan Lembur / Double MP3H
            Row(
              children: [
                Checkbox(
                  value: _isMp3Extra,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) {
                    setState(() => _isMp3Extra = val ?? false);
                  },
                ),
                const Expanded(
                  child: Text(
                    'Tambah Lembur 1x MP3H / Double MP3H',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            if (_isMp3Extra) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      label: 'MP3H Ke-2 Mulai',
                      time: _extraStartTime,
                      icon: Icons.bolt,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _pickTimeDial(
                        context: context,
                        initialTime: _extraStartTime,
                        title: 'JAM MULAI LEMBUR / MP3H KE-2',
                        onSelected: (t) => _extraStartTime = t,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimeButton(
                      label: 'MP3H Ke-2 Selesai',
                      time: _extraEndTime,
                      icon: Icons.bolt,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _pickTimeDial(
                        context: context,
                        initialTime: _extraEndTime,
                        title: 'JAM SELESAI LEMBUR / MP3H KE-2',
                        onSelected: (t) => _extraEndTime = t,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),

            // Preset Jadwal Resmi Segari (Excel Schedule)
            const Row(
              children: [
                Icon(Icons.table_chart_outlined, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 6),
                Text(
                  'PRESET JADWAL RESMI SEGARI',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 1. Shift Reguler (8 Jam + 1 Jam Istirahat)
            const Text(
              '🟢 Shift Reguler (8 Jam):',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('🟡 03:00 - 12:00 (Subuh)', () => _applyPreset('03:00', '12:00')),
                _buildPresetChip('🔵 04:00 - 13:00 (Pagi)', () => _applyPreset('04:00', '13:00')),
                _buildPresetChip('🔵 05:00 - 14:00 (Pagi)', () => _applyPreset('05:00', '14:00')),
                _buildPresetChip('🔵 09:00 - 18:00 (Pagi)', () => _applyPreset('09:00', '18:00')),
                _buildPresetChip('🔵 10:00 - 19:00 (Pagi)', () => _applyPreset('10:00', '19:00')),
                _buildPresetChip('🟠 13:00 - 22:00 (Siang)', () => _applyPreset('13:00', '22:00')),
                _buildPresetChip('🟠 14:00 - 23:00 (Siang)', () => _applyPreset('14:00', '23:00')),
              ],
            ),

            const SizedBox(height: 10),

            // 2. Shift MP3H (3 Jam)
            const Text(
              '🟣 Shift MP3H (3 Jam):',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('🟣 03:00 - 06:00 (Dini)', () => _applyPreset('03:00', '06:00')),
                _buildPresetChip('🟣 09:00 - 12:00 (Pagi)', () => _applyPreset('09:00', '12:00')),
                _buildPresetChip('🟣 19:00 - 22:00 (Malam)', () => _applyPreset('19:00', '22:00')),
                _buildPresetChip('🟣 20:00 - 23:00 (Malam)', () => _applyPreset('20:00', '23:00')),
              ],
            ),

            const SizedBox(height: 10),

            // 3. Reguler + Lembur MP3H (Ada Gap Istirahat 1 Jam)
            const Text(
              '🔥 Reguler + Lembur MP3H (Gap Istirahat 1 Jam):',
              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip(
                  '🔥 09:00-18:00 & 19:00-22:00 (Istirahat 1 Jam)',
                  () => _applyPreset('09:00', '18:00', extra: true, extraStart: '19:00', extraEnd: '22:00'),
                ),
                _buildPresetChip(
                  '🔥 10:00-19:00 & 20:00-23:00 (Istirahat 1 Jam)',
                  () => _applyPreset('10:00', '19:00', extra: true, extraStart: '20:00', extraEnd: '23:00'),
                ),
                _buildPresetChip(
                  '🔥 04:00-13:00 & 19:00-22:00 (Pagi + Malam)',
                  () => _applyPreset('04:00', '13:00', extra: true, extraStart: '19:00', extraEnd: '22:00'),
                ),
                _buildPresetChip(
                  '🔥 03:00-12:00 & 20:00-23:00 (Subuh + Malam)',
                  () => _applyPreset('03:00', '12:00', extra: true, extraStart: '20:00', extraEnd: '23:00'),
                ),
                _buildPresetChip(
                  '⚡ 01:00-04:00 & 04:00-13:00 (MP3H + Pagi)',
                  () => _applyPreset('01:00', '04:00', extra: true, extraStart: '04:00', extraEnd: '13:00'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Gunakan Jam Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () {
                    Navigator.pop(context, resultString);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  Text(
                    _formatTime(time),
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.touch_app, color: color.withOpacity(0.6), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
