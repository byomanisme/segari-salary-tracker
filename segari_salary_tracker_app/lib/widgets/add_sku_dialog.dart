import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sku_entry_model.dart';

class AddSkuDialog extends StatefulWidget {
  final Function(SkuEntry) onSave;
  final List<SkuEntry> existingSkuEntries;
  final String? activeCycleKey;

  const AddSkuDialog({
    Key? key,
    required this.onSave,
    this.existingSkuEntries = const [],
    this.activeCycleKey,
  }) : super(key: key);

  @override
  State<AddSkuDialog> createState() => _AddSkuDialogState();
}

class _AddSkuDialogState extends State<AddSkuDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late DateTime _selectedDate;

  // Mode 1: Dashboard Cumulative Input
  late TextEditingController _cumulativeController;
  late TextEditingController _avgPickingController;
  late TextEditingController _speedTimeController;

  // Mode 2: Manual Direct Input
  late TextEditingController _manualCountController;
  late TextEditingController _notesController;

  int _previousMonthCumulative = 0;
  int _calculatedDelta = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();

    _cumulativeController = TextEditingController();
    _avgPickingController = TextEditingController();
    _speedTimeController = TextEditingController(text: '00:00:25');

    _manualCountController = TextEditingController();
    _notesController = TextEditingController(text: 'Picking & Packing WH Gading Serpong');

    _calculatePreviousCumulative();
  }

  void _calculatePreviousCumulative() {
    final cycle = widget.activeCycleKey ??
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final curDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Sum all SKU entries in this cycle that are before the selected date
    int total = 0;
    for (final e in widget.existingSkuEntries) {
      if (e.date.startsWith(cycle) && e.date.compareTo(curDateStr) < 0) {
        total += e.count;
      }
    }

    setState(() {
      _previousMonthCumulative = total;
      _updateDelta();
    });
  }

  void _updateDelta() {
    final rawText = _cumulativeController.text.replaceAll('.', '').replaceAll(',', '').trim();
    if (rawText.isEmpty) {
      _calculatedDelta = 0;
    } else {
      final inputTotal = int.tryParse(rawText) ?? 0;
      _calculatedDelta = inputTotal - _previousMonthCumulative;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cumulativeController.dispose();
    _avgPickingController.dispose();
    _speedTimeController.dispose();
    _manualCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    int finalCount = 0;
    int? cumulative;
    String? avgPick;
    String? speedTime;

    if (_tabController.index == 0) {
      // Dashboard mode
      final rawCum = _cumulativeController.text.replaceAll('.', '').replaceAll(',', '').trim();
      final totalInDashboard = int.tryParse(rawCum) ?? 0;
      cumulative = totalInDashboard;
      finalCount = (_calculatedDelta > 0) ? _calculatedDelta : totalInDashboard;

      if (_avgPickingController.text.trim().isNotEmpty) {
        avgPick = _avgPickingController.text.trim();
      }
      if (_speedTimeController.text.trim().isNotEmpty) {
        speedTime = _speedTimeController.text.trim();
      }
    } else {
      // Manual direct mode
      final rawManual = _manualCountController.text.replaceAll('.', '').replaceAll(',', '').trim();
      finalCount = int.tryParse(rawManual) ?? 0;
    }

    if (finalCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah SKU harus lebih dari 0!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final entry = SkuEntry(
      id: 'sku_${DateTime.now().millisecondsSinceEpoch}',
      date: dateStr,
      count: finalCount,
      notes: _notesController.text.trim(),
      cumulativeTotal: cumulative,
      avgPicking: avgPick,
      speedTime: speedTime,
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Input Target SKU Segari',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segari WH Location Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: Color(0xFF38BDF8), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'WH Gading Serpong - SDD • Manpower Picking',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Date Picker
                const Text('Tanggal Kerja Picking', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF0284C7),
                            surface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _calculatePreviousCumulative();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_today, size: 15, color: Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Tab Selector (Dashboard Cumulative vs Manual Direct)
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: '📊 Total Monitor Dashboard'),
                      Tab(text: '✍️ Input Manual'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    if (_tabController.index == 0) {
                      // MODE 1: Dashboard Cumulative Input
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Previous Cumulative Banner
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Akumulasi Picking Sebelumnya:',
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                      ),
                                      Text(
                                        '${NumberFormat('#,###', 'id_ID').format(_previousMonthCumulative)} SKU',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Total Picking di Monitor Segari Hari Ini',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _cumulativeController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            validator: (v) {
                              if (_tabController.index == 0) {
                                if (v == null || v.trim().isEmpty) return 'Wajib isi total di monitor dashboard';
                              }
                              return null;
                            },
                            onChanged: (_) {
                              setState(() {
                                _updateDelta();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: _previousMonthCumulative > 0
                                  ? 'contoh: ${_previousMonthCumulative + 500}'
                                  : 'contoh: 530',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              prefixIcon: const Icon(Icons.add_task, color: Color(0xFF38BDF8), size: 18),
                              suffixText: 'SKU',
                              suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Real-time Delta Result Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _calculatedDelta > 0
                                  ? const Color(0xFF064E3B).withOpacity(0.5)
                                  : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _calculatedDelta > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Hasil Picking Hari Ini (Otomatis):',
                                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                                    ),
                                    Text(
                                      _calculatedDelta > 0
                                          ? '+${NumberFormat('#,###', 'id_ID').format(_calculatedDelta)} SKU'
                                          : '0 SKU',
                                      style: TextStyle(
                                        color: _calculatedDelta > 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_cumulativeController.text.isNotEmpty && _previousMonthCumulative > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hitungan: ${_cumulativeController.text} (Dashboard) - $_previousMonthCumulative (Kemarin) = +$_calculatedDelta SKU',
                                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 10),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Optional Dashboard Fields (AVG Picking & Speed)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('AVG Picking', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _avgPickingController,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'contoh: 530',
                                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        filled: true,
                                        isDense: true,
                                        fillColor: const Color(0xFF0F172A),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Waktu / Barang', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _speedTimeController,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: '00:00:25',
                                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        filled: true,
                                        isDense: true,
                                        fillColor: const Color(0xFF0F172A),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // MODE 2: Manual Direct Input
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jumlah SKU Selesai Hari Ini', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _manualCountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            validator: (v) {
                              if (_tabController.index == 1) {
                                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'contoh: 500',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF38BDF8), size: 18),
                              suffixText: 'SKU',
                              suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Notes
                const Text('Keterangan / Posisi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'contoh: Picking Shift Pagi',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    filled: true,
                    isDense: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _save,
          child: const Text(
            'Simpan Target SKU',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
