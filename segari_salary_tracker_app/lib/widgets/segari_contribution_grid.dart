import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../screens/evidence_view_screen.dart';
import 'pixel_mascot_painter.dart';

class SegariContributionGrid extends StatefulWidget {
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;

  const SegariContributionGrid({
    Key? key,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
  }) : super(key: key);

  @override
  State<SegariContributionGrid> createState() => _SegariContributionGridState();
}

class MascotSkin {
  final String id;
  final String name;
  final String title;
  final String headEmoji;
  final Color primaryColor;
  final Color accentColor;
  final String description;

  const MascotSkin({
    required this.id,
    required this.name,
    required this.title,
    required this.headEmoji,
    required this.primaryColor,
    required this.accentColor,
    required this.description,
  });
}

class _SegariContributionGridState extends State<SegariContributionGrid> with WidgetsBindingObserver {
  int _totalWeeks = 16;
  int _focusedMonth = 8; // Default: 8 (Agustus 2026). Can be clicked to switch to 7 (Juli) or 9 (September)
  late DateTime _calendarStart;
  final Random _rng = Random();

  static const List<MascotSkin> _mascotSkins = [
    MascotSkin(
      id: 'snake',
      name: 'Ular Hijau',
      title: 'Ular Belanja Segari',
      headEmoji: '🐍',
      primaryColor: Color(0xFF10B981),
      accentColor: Color(0xFFF97316),
      description: 'Ular legendaris pemburu aneka sembako & buah segar Segari.',
    ),
    MascotSkin(
      id: 'caterpillar',
      name: 'Ulat Sayur',
      title: 'Ulat Sayuran Segari',
      headEmoji: '🐛',
      primaryColor: Color(0xFF84CC16),
      accentColor: Color(0xFFA3E635),
      description: 'Ulat gemas pencinta dedaunan & sayuran hijau segar Segari.',
    ),
    MascotSkin(
      id: 'cat',
      name: 'Kucing Gudang',
      title: 'Si Belang Gudang Segari',
      headEmoji: '🐱',
      primaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFFB923C),
      description: 'Si belang lucu 1 kotak penjaga gudang buah & sembako Segari.',
    ),
    MascotSkin(
      id: 'chicken',
      name: 'Ayam Peternak',
      title: 'Ayam Peternakan Segari',
      headEmoji: '🐔',
      primaryColor: Color(0xFFEAB308),
      accentColor: Color(0xFFFDE047),
      description: 'Ayam putih ceria 1 kotak pencari jagung & telur omega Segari.',
    ),
  ];

  MascotSkin _currentSkin = _mascotSkins[0];

  // Snake AI & Segari Grocery Hunting Engine 🐍🥩🥦🐟🥛🥚🍊
  Timer? _snakeTimer;
  bool _isSnakeActive = true;
  int _itemsEaten = 0;
  int _animTick = 0;
  String _lastEatenName = 'Jeruk Segari 🍊';

  List<Point<int>> _snakeBody = [
    const Point(4, 2),
    const Point(3, 2),
    const Point(2, 2),
  ];
  Point<int> _direction = const Point(1, 0);

  // Grocery Items Map: Position -> Grocery Emoji & Name
  final Map<Point<int>, _GroceryItem> _groceries = {};

  static const List<_GroceryItem> _segariCatalog = [
    // Buah-buahan Segar
    _GroceryItem('🍊', 'Jeruk Segari'),
    _GroceryItem('🍎', 'Apel Fuji'),
    _GroceryItem('🥭', 'Mangga Harum Manis'),
    _GroceryItem('🍌', 'Pisang Cavendish'),
    _GroceryItem('🍇', 'Anggur Merah'),
    _GroceryItem('🍉', 'Semangka Merah'),
    _GroceryItem('🍈', 'Melon Manis'),
    _GroceryItem('🍓', 'Stroberi Ciwidey'),
    _GroceryItem('🥑', 'Alpukat Mentega'),
    _GroceryItem('🍍', 'Nanas Madu'),
    _GroceryItem('🐉', 'Buah Naga Merah'),
    _GroceryItem('🥝', 'Kiwi Hijau'),
    _GroceryItem('🍋', 'Lemon Impor'),
    _GroceryItem('🍐', 'Pir Madu Century'),

    // Sayuran & Jamur
    _GroceryItem('🥦', 'Brokoli Hijau'),
    _GroceryItem('🥕', 'Wortel Brastagi'),
    _GroceryItem('🌶️', 'Cabai Rawit Merah'),
    _GroceryItem('🍅', 'Tomat Merah'),
    _GroceryItem('🌽', 'Jagung Manis'),
    _GroceryItem('🧅', 'Bawang Merah Brebes'),
    _GroceryItem('🧄', 'Bawang Putih Kating'),
    _GroceryItem('🥔', 'Kentang Dieng'),
    _GroceryItem('🥬', 'Selada Keriting'),
    _GroceryItem('🍆', 'Terong Ungu'),
    _GroceryItem('🍄', 'Jamur Tiram Segar'),
    _GroceryItem('🫑', 'Paprika Merah'),
    _GroceryItem('🥒', 'Timun Jepang'),
    _GroceryItem('🎃', 'Labu Kuning Manis'),

    // Daging & Seafood
    _GroceryItem('🥩', 'Daging Sapi Paha'),
    _GroceryItem('🍗', 'Ayam Potong Utuh'),
    _GroceryItem('🐟', 'Ikan Salmon Segar'),
    _GroceryItem('🦐', 'Udang Vaname'),
    _GroceryItem('🦑', 'Cumi Segar'),
    _GroceryItem('🥚', 'Telur Ayam Omega'),
    _GroceryItem('🥓', 'Daging Cincang'),
    _GroceryItem('🦀', 'Kepiting Segar'),

    // Dairy & Bakery
    _GroceryItem('🥛', 'Susu Murni Fresh'),
    _GroceryItem('🧀', 'Keju Cheddar'),
    _GroceryItem('🧈', 'Mentega Anchor'),
    _GroceryItem('🍞', 'Roti Gandum Tawar'),
    _GroceryItem('🥐', 'Croissant Butter'),

    // Sembako & Minuman
    _GroceryItem('🍚', 'Beras Pandan Wangi'),
    _GroceryItem('🫒', 'Minyak Kelapa Murni'),
    _GroceryItem('🍯', 'Madu Hutan Segari'),
    _GroceryItem('☕', 'Kopi Robusta Segari'),
    _GroceryItem('🍵', 'Teh Hijau Herbal'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedSkin();
    _initCalendarDates();
    _spawnGroceries();
    _startSnake();
  }

  Future<void> _loadSavedSkin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('segari_mascot_skin_id');
      if (savedId != null) {
        final found = _mascotSkins.firstWhere((s) => s.id == savedId, orElse: () => _mascotSkins[0]);
        if (mounted) {
          setState(() {
            _currentSkin = found;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading mascot skin: $e');
    }
  }

  Future<void> _changeSkin(MascotSkin skin) async {
    setState(() {
      _currentSkin = skin;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('segari_mascot_skin_id', skin.id);
    } catch (e) {
      debugPrint('Error saving mascot skin: $e');
    }
  }

  void _showSkinSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _currentSkin.primaryColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_currentSkin.headEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Karakter Maskot 🎨',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Ganti skin hewan/karakter pemburu SKU Segari',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 12),

                    // Grid of 6 Skins
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _mascotSkins.map((skin) {
                            final isSelected = skin.id == _currentSkin.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? skin.primaryColor.withOpacity(0.12) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? skin.primaryColor : Colors.white.withOpacity(0.06),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  _changeSkin(skin);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Skin berhasil diubah ke ${skin.name} ${skin.headEmoji}!'),
                                      backgroundColor: skin.primaryColor,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: skin.primaryColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: skin.primaryColor.withOpacity(0.4)),
                                        ),
                                        child: Center(
                                          child: PixelMascotWidget(
                                            skinId: skin.id,
                                            size: 28,
                                            frameIndex: _animTick,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  skin.name,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 6),
                                                if (isSelected)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: skin.primaryColor,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text('Aktif ✓', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              skin.description,
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isSnakeActive && (_snakeTimer == null || !_snakeTimer!.isActive)) {
        _startSnake();
      }
    } else {
      // Pause snake timer immediately when app is closed, minimized, or inactive
      _snakeTimer?.cancel();
      _snakeTimer = null;
    }
  }

  @override
  void didUpdateWidget(covariant SegariContributionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initCalendarDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snakeTimer?.cancel();
    super.dispose();
  }

  void _initCalendarDates() {
    // Center date based on _focusedMonth (2026)
    final refDate = DateTime(2026, _focusedMonth, 15);
    final centerMonday = refDate.subtract(Duration(days: refDate.weekday - 1));
    // Center the calendar with 7 weeks before and 8 weeks after
    _calendarStart = centerMonday.subtract(const Duration(days: 7 * 7));
  }

  void _switchFocusedMonth(int month) {
    setState(() {
      _focusedMonth = month;
      _initCalendarDates();
      _spawnGroceries();
    });
  }

  void _spawnGroceries() {
    _groceries.clear();
    const groceryCount = 6;
    int attempts = 0;

    while (_groceries.length < groceryCount && attempts < 150) {
      attempts++;
      final x = _rng.nextInt(_totalWeeks);
      final y = _rng.nextInt(7);
      final pt = Point(x, y);

      if (!_snakeBody.contains(pt) && !_groceries.containsKey(pt)) {
        _groceries[pt] = _segariCatalog[_rng.nextInt(_segariCatalog.length)];
      }
    }
  }

  void _startSnake() {
    _snakeTimer?.cancel();
    // Fast & smooth timer: 150ms
    _snakeTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_isSnakeActive || !mounted) return;
      _moveSnakeStep();
    });
  }

  void _moveSnakeStep() {
    setState(() {
      final head = _snakeBody.first;

      // 1. Find nearest Segari grocery item
      Point<int>? targetItem;
      int minDistance = 9999;

      for (final g in _groceries.keys) {
        final dist = (head.x - g.x).abs() + (head.y - g.y).abs();
        if (dist < minDistance) {
          minDistance = dist;
          targetItem = g;
        }
      }

      // 2. Determine best path towards target
      final possibleDirections = [
        const Point(1, 0),
        const Point(-1, 0),
        const Point(0, 1),
        const Point(0, -1),
      ];

      Point<int>? bestDir;

      if (targetItem != null) {
        final target = targetItem;
        possibleDirections.sort((a, b) {
          final nextA = Point(head.x + a.x, head.y + a.y);
          final nextB = Point(head.x + b.x, head.y + b.y);
          final distA = (nextA.x - target.x).abs() + (nextA.y - target.y).abs();
          final distB = (nextB.x - target.x).abs() + (nextB.y - target.y).abs();
          return distA.compareTo(distB);
        });
      }

      for (final dir in possibleDirections) {
        if (dir.x == -_direction.x && dir.y == -_direction.y) continue;

        final nextX = head.x + dir.x;
        final nextY = head.y + dir.y;

        if (nextX >= 0 && nextX < _totalWeeks && nextY >= 0 && nextY < 7) {
          final nextPt = Point(nextX, nextY);
          if (!_snakeBody.sublist(0, _snakeBody.length - 1).contains(nextPt)) {
            bestDir = dir;
            break;
          }
        }
      }

      if (bestDir == null) {
        for (final dir in possibleDirections) {
          final nextX = head.x + dir.x;
          final nextY = head.y + dir.y;
          if (nextX >= 0 && nextX < _totalWeeks && nextY >= 0 && nextY < 7) {
            bestDir = dir;
            break;
          }
        }
      }

      if (bestDir != null) {
        _direction = bestDir;
      }

      var nextX = head.x + _direction.x;
      var nextY = head.y + _direction.y;

      if (nextX < 0) nextX = _totalWeeks - 1;
      if (nextX >= _totalWeeks) nextX = 0;
      if (nextY < 0) nextY = 6;
      if (nextY >= 7) nextY = 0;

      final newHead = Point(nextX, nextY);

      // Check if grocery item eaten 🥦🥩🍊
      bool ateItem = false;
      if (_groceries.containsKey(newHead)) {
        final item = _groceries.remove(newHead)!;
        _itemsEaten++;
        _lastEatenName = '${item.name} ${item.emoji}';
        ateItem = true;

        if (_groceries.isEmpty) {
          _spawnGroceries();
        }
      }

      _snakeBody.insert(0, newHead);
      _animTick++;

      final isMultiSegment = (_currentSkin.id == 'snake' || _currentSkin.id == 'caterpillar');
      final maxLength = isMultiSegment ? (ateItem ? min(6, _snakeBody.length) : 3) : 1;
      while (_snakeBody.length > maxLength) {
        _snakeBody.removeLast();
      }
    });
  }

  Point<int> _getSegmentDirection(int index) {
    if (_snakeBody.isEmpty) return const Point(1, 0);
    if (index == 0) return _direction;

    final prev = _snakeBody[index - 1];
    final current = _snakeBody[index];

    var dx = prev.x - current.x;
    var dy = prev.y - current.y;

    if (dx > 1) dx = -1;
    if (dx < -1) dx = 1;
    if (dy > 1) dy = -1;
    if (dy < -1) dy = 1;

    if (dx == 0 && dy == 0) return _direction;
    return Point(dx, dy);
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  AttendanceRecord? _findRecordForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    for (final r in widget.records) {
      if (r.date == dateStr) return r;
    }
    return null;
  }

  Color _getColorForRecord(AttendanceRecord? record, int monthNumber) {
    if (record == null) {
      if (monthNumber == _focusedMonth) return const Color(0xFF1E293B);
      if (monthNumber < _focusedMonth) return const Color(0xFF151D2E);
      return const Color(0xFF101726);
    }
    switch (record.type) {
      case 'off':
        return const Color(0xFFEF4444); // 🔴 Merah (OFF / Libur) persis seperti jadwal Segari
      case 'mp3':
        return const Color(0xFF8B5CF6); // 🟣 Ungu (Shift MP3H 3 Jam)
      case 'reguler_mp3':
        return const Color(0xFF10B981); // 🟢 Hijau Emerald (Reguler + Lembur MP3H 11 Jam)
      case 'double_mp3':
        return const Color(0xFF3B82F6); // 🔵 Biru (Double MP3H 6 Jam)
      case 'training':
        return const Color(0xFFEAB308); // 🟡 Kuning (Training)
      case 'reguler':
        final start = record.shiftHours.trim();
        if (start.startsWith('13') || start.startsWith('14')) {
          return const Color(0xFFF97316); // 🟠 Oranye (Shift Siang / Sore 13:00-22:00 / 14:00-23:00)
        } else if (start.startsWith('03')) {
          return const Color(0xFFEAB308); // 🟡 Kuning (Shift Subuh 03:00-12:00)
        }
        return const Color(0xFF06B6D4); // 🔷 Cyan / Biru Muda (Shift Pagi 04:00-13:00 / 05:00-14:00 / 09:00-18:00)
      default:
        return const Color(0xFF06B6D4);
    }
  }

  void _showDayDetails(BuildContext context, DateTime date, AttendanceRecord? record) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = dayNames[date.weekday - 1];
    final dateStr = '${date.day} ${monthNames[date.month - 1]} ${date.year}';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayName, $dateStr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record != null ? record.typeLabel : 'Tidak Ada Catatan Shift',
                          style: TextStyle(
                            color: record != null ? _getColorForRecord(record, date.month) : const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _getColorForRecord(record, date.month),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        record?.type == 'off'
                            ? Icons.bed
                            : (record != null ? Icons.check : Icons.calendar_today),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 12),
                if (record != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jam Kerja:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text(
                        record.shiftHours.isNotEmpty ? record.shiftHours : '-',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upah Harian:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text(
                        _formatCurrency(record.rate),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Catatan:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        Flexible(
                          child: Text(
                            record.notes,
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Day's Penalty Log
                  if (widget.penalties.any((p) => p.date == dateStr)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text(
                                'Denda Komplain QC di Hari Ini:',
                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...widget.penalties.where((p) => p.date == dateStr).map((p) => Text(
                            '• ${p.typeLabel}: -${_formatCurrency(p.amount)} (${p.notes.isNotEmpty ? p.notes : "Denda Standar"})',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // Day's SKU Entry Log
                  if (widget.skuEntries.any((s) => s.date == dateStr)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2, size: 13, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text(
                                'Catatan Picking SKU di Hari Ini:',
                                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...widget.skuEntries.where((s) => s.date == dateStr).map((s) => Text(
                            '• +${s.count} SKU (${s.notes.isNotEmpty ? s.notes : "Target Picking"})',
                            style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 11),
                          )),
                        ],
                      ),
                    ),
                  ],

                  if (record.evidenceAssetPath != null || record.evidenceLocalFilePath != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Lihat Foto Bukti Jadwal'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EvidenceViewScreen(
                                dateStr: '${record.dayName}, ${record.date}',
                                assetPath: record.evidenceAssetPath,
                                localFilePath: record.evidenceLocalFilePath,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  const Text(
                    'Tidak ada catatan shift pada tanggal ini.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int workingDays = 0;
    int offDays = 0;
    int totalEstimatedHours = 0;

    for (final r in widget.records) {
      if (r.type != 'off') {
        workingDays++;
        if (r.type == 'reguler') {
          totalEstimatedHours += 8;
        } else if (r.type == 'mp3' || r.type == 'training') {
          totalEstimatedHours += 3;
        } else if (r.type == 'reguler_mp3') {
          totalEstimatedHours += 11;
        }
      } else {
        offDays++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Segari Mascot & Status & Skin Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showSkinSelectorDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _currentSkin.primaryColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _currentSkin.primaryColor.withOpacity(0.4)),
                        ),
                        child: PixelMascotWidget(
                          skinId: _currentSkin.id,
                          size: 20,
                          frameIndex: _animTick,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _currentSkin.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _currentSkin.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _currentSkin.primaryColor.withOpacity(0.35)),
                                ),
                                child: const Text('Skin 🎨', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'Memakan: ',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                              ),
                              Text(
                                _lastEatenName,
                                style: TextStyle(color: _currentSkin.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' ($_itemsEaten SKU)',
                                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => _showSkinSelectorDialog(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.palette_outlined, color: Color(0xFF38BDF8), size: 14),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isSnakeActive = !_isSnakeActive),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isSnakeActive ? const Color(0xFF064E3B) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSnakeActive ? const Color(0xFF10B981) : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSnakeActive ? Icons.pause : Icons.play_arrow,
                            color: _isSnakeActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isSnakeActive ? 'Pause' : 'Play',
                            style: TextStyle(
                              color: _isSnakeActive ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Mini Stats
          Row(
            children: [
              _buildMetric('Total Jam', '$totalEstimatedHours Jam', Icons.access_time),
              const SizedBox(width: 6),
              _buildMetric('Shift Aktif', '$workingDays Hari', Icons.check_circle_outline),
              const SizedBox(width: 6),
              _buildMetric('Hari Libur', '$offDays Hari', Icons.bed_outlined),
            ],
          ),

          const SizedBox(height: 12),

          // Clickable Interactive Month Switcher (Juli, Agustus, September)
          Row(
            children: [
              _buildInteractiveMonthTab(
                monthNumber: 7,
                label: 'Juli 2026',
                isSelected: _focusedMonth == 7,
              ),
              const SizedBox(width: 6),
              _buildInteractiveMonthTab(
                monthNumber: 8,
                label: 'Agustus 2026',
                isSelected: _focusedMonth == 8,
              ),
              const SizedBox(width: 6),
              _buildInteractiveMonthTab(
                monthNumber: 9,
                label: 'September 2026',
                isSelected: _focusedMonth == 9,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Responsive Full-Width LayoutBuilder Grid
          LayoutBuilder(
            builder: (context, constraints) {
              const dayLabelWidth = 26.0;
              final gridAvailableWidth = constraints.maxWidth - dayLabelWidth - 6;

              final columnCount = (gridAvailableWidth / 21.0).floor().clamp(12, 20);
              _totalWeeks = columnCount;

              final cellSize = (gridAvailableWidth / columnCount) - 3.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Labels
                  Column(
                    children: [
                      _buildDayLabel('Sen', cellSize),
                      _buildDayLabel('Sel', cellSize),
                      _buildDayLabel('Rab', cellSize),
                      _buildDayLabel('Kam', cellSize),
                      _buildDayLabel('Jum', cellSize),
                      _buildDayLabel('Sab', cellSize),
                      _buildDayLabel('Min', cellSize),
                    ],
                  ),
                  const SizedBox(width: 6),

                  // Edge-to-Edge Grid Columns
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(columnCount, (weekIndex) {
                        return Column(
                          children: List.generate(7, (dayIndex) {
                            final currentDayDate = _calendarStart.add(
                              Duration(days: (weekIndex * 7) + dayIndex),
                            );

                            final rec = _findRecordForDate(currentDayDate);
                            final month = currentDayDate.month;
                            final baseColor = _getColorForRecord(rec, month);

                            final currentPoint = Point(weekIndex, dayIndex);
                            final segmentIndex = _snakeBody.indexOf(currentPoint);
                            final isMascotSegment = segmentIndex >= 0;
                            final hasGrocery = _groceries.containsKey(currentPoint);

                            Widget cellContent;
                            Color cellColor = baseColor;
                            BoxBorder border = Border.all(
                              color: month == _focusedMonth
                                  ? (rec != null ? Colors.white.withOpacity(0.25) : const Color(0xFF10B981).withOpacity(0.2))
                                  : Colors.white.withOpacity(0.04),
                              width: month == _focusedMonth ? 0.9 : 0.6,
                            );
                            List<BoxShadow>? shadows;

                            if (isMascotSegment) {
                              final isHead = segmentIndex == 0;
                              cellColor = _currentSkin.primaryColor.withOpacity(isHead ? 0.25 : 0.14);
                              border = Border.all(
                                color: _currentSkin.primaryColor.withOpacity(isHead ? 1.0 : 0.6),
                                width: isHead ? 1.2 : 0.8,
                              );
                              if (isHead) {
                                shadows = [
                                  BoxShadow(
                                    color: _currentSkin.primaryColor.withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 0.5,
                                  ),
                                ];
                              }

                              MascotPart part = MascotPart.head;
                              if (segmentIndex == 0) {
                                part = MascotPart.head;
                              } else if (segmentIndex == _snakeBody.length - 1) {
                                part = MascotPart.tail;
                              } else {
                                part = MascotPart.body;
                              }

                              cellContent = Center(
                                child: PixelMascotWidget(
                                  skinId: _currentSkin.id,
                                  part: part,
                                  bodyIndex: segmentIndex,
                                  totalBodyLength: _snakeBody.length,
                                  direction: _getSegmentDirection(segmentIndex),
                                  animTick: _animTick,
                                  size: cellSize,
                                ),
                              );
                            } else if (hasGrocery) {
                              // Grocery Item Cell (Meat, Fish, Veggies, Milk, Eggs, Fruits)
                              cellColor = const Color(0xFF0F291E);
                              border = Border.all(color: const Color(0xFFF59E0B), width: 1);
                              cellContent = Center(
                                child: Text(
                                  _groceries[currentPoint]?.emoji ?? '🥦',
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            } else {
                              cellContent = Center(
                                child: Text(
                                  '${currentDayDate.day}',
                                  style: TextStyle(
                                    color: month == _focusedMonth
                                        ? (rec != null ? Colors.white : const Color(0xFF64748B))
                                        : const Color(0xFF334155),
                                    fontSize: 7,
                                    fontWeight: rec != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }

                            return InkWell(
                              onTap: () => _showDayDetails(context, currentDayDate, rec),
                              borderRadius: BorderRadius.circular(3.5),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                margin: const EdgeInsets.symmetric(vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(3.5),
                                  border: border,
                                  boxShadow: shadows,
                                ),
                                child: cellContent,
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 8),

          // Segari Shift & Status Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFFEF4444), 'OFF (Merah)'),
              _buildLegendItem(const Color(0xFF8B5CF6), 'MP3H (Ungu)'),
              _buildLegendItem(const Color(0xFFF97316), 'Siang (Oranye)'),
              _buildLegendItem(const Color(0xFFEAB308), 'Subuh (Kuning)'),
              _buildLegendItem(const Color(0xFF06B6D4), 'Pagi (Cyan)'),
              _buildLegendItem(const Color(0xFF10B981), 'Lembur (11h)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMonthTab({
    required int monthNumber,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _switchFocusedMonth(monthNumber),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 11, color: Color(0xFF064E3B)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayLabel(String label, double size) {
    return Container(
      width: 26,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: const Color(0xFF10B981)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8),
                  ),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
        ),
      ],
    );
  }
}

class _GroceryItem {
  final String emoji;
  final String name;
  const _GroceryItem(this.emoji, this.name);
}
