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
  final String? initialCycleKey;
  final Function(int year, int month)? onMonthChanged;

  const SegariContributionGrid({
    super.key,
    required this.records,
    this.penalties = const [],
    this.skuEntries = const [],
    this.initialCycleKey,
    this.onMonthChanged,
  });

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
  late int _focusedYear;
  late int _focusedMonth;
  bool _isMonthlyCalendarView = true; // Default: clean monthly calendar grid view
  late DateTime _calendarStart;
  final Random _rng = Random();

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

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
    final now = DateTime.now();
    if (widget.initialCycleKey != null && widget.initialCycleKey!.contains('-')) {
      final parts = widget.initialCycleKey!.split('-');
      _focusedYear = int.tryParse(parts[0]) ?? now.year;
      _focusedMonth = int.tryParse(parts[1]) ?? now.month;
    } else {
      _focusedYear = now.year;
      _focusedMonth = now.month;
    }
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
    if (widget.initialCycleKey != null && widget.initialCycleKey != oldWidget.initialCycleKey) {
      final parts = widget.initialCycleKey!.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]) ?? _focusedYear;
        final m = int.tryParse(parts[1]) ?? _focusedMonth;
        if (y != _focusedYear || m != _focusedMonth) {
          _focusedYear = y;
          _focusedMonth = m;
          _spawnGroceries();
        }
      }
    }
    _initCalendarDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snakeTimer?.cancel();
    super.dispose();
  }

  void _initCalendarDates() {
    // Start from the Monday on or before the 1st day of _focusedMonth
    final firstDayOfMonth = DateTime(_focusedYear, _focusedMonth, 1);
    final startMonday = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    _calendarStart = startMonday;
  }

  void _switchFocusedMonth(int month, {int? year}) {
    setState(() {
      _focusedMonth = month;
      if (year != null) _focusedYear = year;
      _initCalendarDates();
      _spawnGroceries();
    });
    widget.onMonthChanged?.call(_focusedYear, _focusedMonth);
  }

  void _shiftMonth(int offset) {
    setState(() {
      _focusedMonth += offset;
      if (_focusedMonth > 12) {
        _focusedMonth = 1;
        _focusedYear += 1;
      } else if (_focusedMonth < 1) {
        _focusedMonth = 12;
        _focusedYear -= 1;
      }
      _initCalendarDates();
      _spawnGroceries();
    });
    widget.onMonthChanged?.call(_focusedYear, _focusedMonth);
  }

  void _showMonthYearPicker(BuildContext context) {
    int tempYear = _focusedYear;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Bulan & Tahun Kalender',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Year Navigator Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF10B981)),
                            onPressed: () {
                              setDialogState(() {
                                tempYear--;
                              });
                            },
                          ),
                          Text(
                            '$tempYear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF10B981)),
                            onPressed: () {
                              setDialogState(() {
                                tempYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 12 Months Grid (4 rows x 3 columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.3,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = (monthNum == _focusedMonth && tempYear == _focusedYear);
                        return InkWell(
                          onTap: () {
                            _switchFocusedMonth(monthNum, year: tempYear);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _monthNames[index],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF064E3B) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
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

  Color _getColorForRecord(AttendanceRecord? record, int monthNumber, {bool ignoreFocusedMonth = false}) {
    // Only display shift colors for the currently selected/focused month!
    if (!ignoreFocusedMonth && monthNumber != _focusedMonth) {
      return const Color(0xFF0F172A);
    }
    if (record == null) {
      return monthNumber == _focusedMonth ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
    }
    switch (record.type) {
      case 'off':
        return const Color(0xFFEF4444); // 🔴 Merah (OFF / Libur)
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
          return const Color(0xFFF97316); // 🟠 Oranye (Shift Siang / Sore 13:00 / 14:00)
        } else if (start.startsWith('03')) {
          return const Color(0xFFEAB308); // 🟡 Kuning (Shift Subuh 03:00)
        }
        return const Color(0xFF06B6D4); // 🔷 Cyan / Biru Muda (Shift Pagi)
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
                            color: record != null ? _getColorForRecord(record, date.month, ignoreFocusedMonth: true) : const Color(0xFF94A3B8),
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
                        color: _getColorForRecord(record, date.month, ignoreFocusedMonth: true),
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
    // 1. Calculate metrics specifically for the currently focused month and year!
    final currentCyclePrefix = '$_focusedYear-${_focusedMonth.toString().padLeft(2, '0')}';
    final monthRecords = widget.records.where((r) => r.date.startsWith(currentCyclePrefix)).toList();
    final Map<String, AttendanceRecord> recordMap = {
      for (final r in widget.records) r.date: r,
    };

    int workingDays = 0;
    int offDays = 0;
    int totalEstimatedHours = 0;

    for (final r in monthRecords) {
      if (r.type != 'off') {
        workingDays++;
        if (r.type == 'reguler') {
          totalEstimatedHours += 8;
        } else if (r.type == 'mp3' || r.type == 'training') {
          totalEstimatedHours += 3;
        } else if (r.type == 'reguler_mp3') {
          totalEstimatedHours += 11;
        } else if (r.type == 'double_mp3') {
          totalEstimatedHours += 6;
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
          // 1. Header: Month & Year Navigator + Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Clickable Month & Year Dropdown
              InkWell(
                onTap: () => _showMonthYearPicker(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${_monthNames[_focusedMonth - 1]} $_focusedYear',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981), size: 16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  // Prev Month Arrow
                  InkWell(
                    onTap: () => _shiftMonth(-1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.chevron_left, color: Color(0xFF10B981), size: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Next Month Arrow
                  InkWell(
                    onTap: () => _shiftMonth(1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View Mode Toggle (Kalender / Matriks)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _isMonthlyCalendarView = true),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isMonthlyCalendarView ? const Color(0xFF10B981) : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            ),
                            child: Icon(
                              Icons.calendar_view_month,
                              size: 15,
                              color: _isMonthlyCalendarView ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isMonthlyCalendarView = false),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: !_isMonthlyCalendarView ? const Color(0xFF10B981) : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            ),
                            child: Icon(
                              Icons.grid_view,
                              size: 15,
                              color: !_isMonthlyCalendarView ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Mini Stats Row (Synchronized to selected month)
          Row(
            children: [
              _buildMetric('Shift Aktif', '$workingDays Hari', Icons.check_circle_outline),
              const SizedBox(width: 6),
              _buildMetric('Hari Libur', '$offDays Hari', Icons.bed_outlined),
              const SizedBox(width: 6),
              _buildMetric('Total Jam', '$totalEstimatedHours Jam', Icons.access_time),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Main Calendar Content: Monthly Calendar Grid OR Mascot Matrix
          if (_isMonthlyCalendarView)
            _buildMonthlyCalendarView(recordMap)
          else
            _buildMascotMatrixView(),

          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 8),

          // 5. Segari Shift & Status Legend
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
              _buildLegendItem(const Color(0xFF10B981), 'Lembur (11 Jam)'),
              _buildLegendItem(const Color(0xFF3B82F6), 'Double (6 Jam)'),
            ],
          ),
        ],
      ),
    );
  }

  // 📅 Clean & Intuitive 1-Month Standard Calendar Grid
  Widget _buildMonthlyCalendarView(Map<String, AttendanceRecord> recordMap) {
    final firstDayOfMonth = DateTime(_focusedYear, _focusedMonth, 1);
    final daysInMonth = DateTime(_focusedYear, _focusedMonth + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final prefixDays = startWeekday - 1; // Number of leading empty cells before day 1

    final totalCells = prefixDays + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    final now = DateTime.now();

    return Column(
      children: [
        // Day Headers: Sen, Sel, Rab, Kam, Jum, Sab, Min
        const Row(
          children: [
            _DayHeaderCell('Sen'),
            _DayHeaderCell('Sel'),
            _DayHeaderCell('Rab'),
            _DayHeaderCell('Kam'),
            _DayHeaderCell('Jum'),
            _DayHeaderCell('Sab'),
            _DayHeaderCell('Min'),
          ],
        ),
        const SizedBox(height: 6),
        // Day Cells Grid
        for (int r = 0; r < rowsCount; r++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                for (int c = 0; c < 7; c++) ...[
                  Builder(
                    builder: (_) {
                      final cellIndex = (r * 7) + c;
                      final dayNumber = cellIndex - prefixDays + 1;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const Expanded(
                          child: SizedBox(height: 48),
                        );
                      }

                      final dayDate = DateTime(_focusedYear, _focusedMonth, dayNumber);
                      final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);
                      final record = recordMap[dateKey];
                      final isToday = now.year == dayDate.year &&
                          now.month == dayDate.month &&
                          now.day == dayDate.day;

                      final hasPenalty = widget.penalties.any((p) => p.date == dateKey);
                      final hasSku = widget.skuEntries.any((s) => s.date == dateKey);

                      final Color cellColor = _getColorForRecord(record, _focusedMonth);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _showDayDetails(context, dayDate, record),
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: record != null ? cellColor : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isToday
                                    ? const Color(0xFF38BDF8)
                                    : (record != null
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.06)),
                                width: isToday ? 2.0 : 1.0,
                              ),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        color: record != null
                                            ? Colors.white
                                            : (isToday ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8)),
                                        fontSize: 12,
                                        fontWeight: (isToday || record != null)
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (hasPenalty) ...[
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                    if (hasSku) ...[
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFDE047),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _buildShiftBadge(record, isToday),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Mini Shift Badge inside Calendar Day Cell
  Widget _buildShiftBadge(AttendanceRecord? record, bool isToday) {
    if (record == null) {
      if (isToday) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Hari Ini',
            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold),
          ),
        );
      }
      return const SizedBox(height: 12);
    }

    String label = '';
    if (record.type == 'off') {
      label = 'OFF';
    } else if (record.type == 'mp3') {
      label = '3 Jam';
    } else if (record.type == 'training') {
      label = 'Trn';
    } else if (record.type == 'reguler_mp3') {
      label = '11 Jam';
    } else if (record.type == 'double_mp3') {
      label = '6 Jam';
    } else if (record.type == 'reguler') {
      final start = record.shiftHours.trim();
      if (start.startsWith('13') || start.startsWith('14')) {
        label = 'Siang';
      } else if (start.startsWith('03')) {
        label = 'Subuh';
      } else {
        label = 'Pagi';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🎮 Responsive Mascot & Grocery Game Matrix View
  Widget _buildMascotMatrixView() {
    return Column(
      children: [
        // Mascot Status Header
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
                                fontSize: 13,
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

        // LayoutBuilder Grid
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

                // Edge-to-Edge Grid Columns with Monthly Boundary Gap
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int weekIndex = 0; weekIndex < columnCount; weekIndex++) ...[
                        // 🌟 Visual Gap & Divider between months so user can easily differentiate months!
                        if (weekIndex > 0 &&
                            _calendarStart.add(Duration(days: weekIndex * 7)).month !=
                            _calendarStart.add(Duration(days: (weekIndex - 1) * 7)).month) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 1.5,
                            height: 7 * (cellSize + 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                        Column(
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
                                  ? (rec != null ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.2))
                                  : Colors.white.withValues(alpha: 0.02),
                              width: month == _focusedMonth ? 0.9 : 0.5,
                            );
                            List<BoxShadow>? shadows;

                            if (isMascotSegment) {
                              final isHead = segmentIndex == 0;
                              cellColor = _currentSkin.primaryColor.withValues(alpha: isHead ? 0.25 : 0.14);
                              border = Border.all(
                                color: _currentSkin.primaryColor.withValues(alpha: isHead ? 1.0 : 0.6),
                                width: isHead ? 1.2 : 0.8,
                              );
                              if (isHead) {
                                shadows = [
                                  BoxShadow(
                                    color: _currentSkin.primaryColor.withValues(alpha: 0.6),
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
                                        : const Color(0xFF1E293B),
                                    fontSize: 7,
                                    fontWeight: (month == _focusedMonth && rec != null) ? FontWeight.bold : FontWeight.normal,
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
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Dynamic 3-Month Quick Tab
  Widget _buildDynamicMonthTab(int offset) {
    int targetMonth = _focusedMonth + offset;
    int targetYear = _focusedYear;
    if (targetMonth > 12) {
      targetMonth = 1;
      targetYear++;
    } else if (targetMonth < 1) {
      targetMonth = 12;
      targetYear--;
    }

    final isSelected = offset == 0;
    final label = '${_monthNames[targetMonth - 1].substring(0, 3)} $targetYear';

    return Expanded(
      child: InkWell(
        onTap: () => _switchFocusedMonth(targetMonth, year: targetYear),
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
                const Icon(Icons.check, size: 10, color: Color(0xFF064E3B)),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF94A3B8),
                  fontSize: 10.5,
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

class _DayHeaderCell extends StatelessWidget {
  final String text;
  const _DayHeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GroceryItem {
  final String emoji;
  final String name;
  const _GroceryItem(this.emoji, this.name);
}
