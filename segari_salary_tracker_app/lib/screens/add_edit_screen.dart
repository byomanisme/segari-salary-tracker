import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_settings.dart';
import '../widgets/shift_time_picker_dialog.dart';

class AddEditScreen extends StatefulWidget {
  final AttendanceRecord? record;
  final UserSettings settings;

  const AddEditScreen({
    Key? key,
    this.record,
    required this.settings,
  }) : super(key: key);

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _shiftType;
  late TextEditingController _hoursController;
  late TextEditingController _rateController;
  late TextEditingController _notesController;
  String? _localPhotoPath;
  String? _assetPhotoPath;

  List<Map<String, String>> get _shiftTypes => [
    {'value': 'reguler', 'label': 'Shift Reguler 8 Jam (Rp ${widget.settings.regulerRate})'},
    {'value': 'mp3', 'label': 'Shift MP3H 3 Jam (Rp ${widget.settings.mp3Rate})'},
    {'value': 'reguler_mp3', 'label': 'Reguler + Lembur 1x MP3H (Rp ${widget.settings.regulerRate + widget.settings.mp3Rate})'},
    {'value': 'double_mp3', 'label': 'Double MP3H (2x MP3H / 6 Jam) (Rp ${widget.settings.mp3Rate * 2})'},
    {'value': 'training', 'label': 'Training (MP3H) (Rp ${widget.settings.mp3Rate})'},
    {'value': 'off', 'label': 'Libur / OFF (Rp 0)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _selectedDate = DateTime.tryParse(widget.record!.date) ?? DateTime.now();
      _shiftType = widget.record!.type;
      _hoursController = TextEditingController(text: widget.record!.shiftHours);
      _rateController = TextEditingController(text: widget.record!.rate.toString());
      _notesController = TextEditingController(text: widget.record!.notes);
      _localPhotoPath = widget.record!.evidenceLocalFilePath;
      _assetPhotoPath = widget.record!.evidenceAssetPath;
    } else {
      _selectedDate = DateTime.now();
      _shiftType = 'reguler';
      _hoursController = TextEditingController(text: '09:00 - 18:00');
      _rateController = TextEditingController(text: widget.settings.regulerRate.toString());
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getDayName(DateTime date) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[date.weekday - 1];
  }

  void _onShiftTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _shiftType = newType;
      if (newType == 'reguler') {
        _rateController.text = widget.settings.regulerRate.toString();
        if (_hoursController.text.isEmpty || _hoursController.text == '-' || _hoursController.text.contains('&')) {
          _hoursController.text = '09:00 - 18:00';
        }
      } else if (newType == 'mp3') {
        _rateController.text = widget.settings.mp3Rate.toString();
        if (_hoursController.text.isEmpty || _hoursController.text == '-' || _hoursController.text.contains('&')) {
          _hoursController.text = '19:00 - 22:00';
        }
      } else if (newType == 'reguler_mp3') {
        _rateController.text = (widget.settings.regulerRate + widget.settings.mp3Rate).toString();
        _hoursController.text = '09:00 - 18:00 & 19:00 - 22:00';
      } else if (newType == 'double_mp3') {
        _rateController.text = (widget.settings.mp3Rate * 2).toString();
        _hoursController.text = '03:00 - 06:00 & 20:00 - 23:00';
      } else if (newType == 'training') {
        _rateController.text = widget.settings.mp3Rate.toString();
        _hoursController.text = '09:00 - 12:00';
      } else if (newType == 'off') {
        _rateController.text = '0';
        _hoursController.text = '-';
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _localPhotoPath = result.files.single.path;
          _assetPhotoPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'reguler':
        return 'Reguler (8 Jam)';
      case 'mp3':
        return 'MP3H (3 Jam)';
      case 'reguler_mp3':
        return 'Reguler + Lembur MP3H (11 Jam)';
      case 'double_mp3':
        return 'Double MP3H (2x MP3H / 6 Jam)';
      case 'training':
        return 'Training (MP3H)';
      case 'off':
        return 'OFF (Libur)';
      default:
        return type.toUpperCase();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayName = _getDayName(_selectedDate);
    final rateVal = int.tryParse(_rateController.text) ?? 0;
    final hoursVal = _hoursController.text.trim();
    final notesVal = _notesController.text.trim();

    final record = AttendanceRecord(
      id: widget.record?.id ?? 'rec_${dateStr.replaceAll('-', '')}',
      date: dateStr,
      dayName: dayName,
      type: _shiftType,
      typeLabel: _getTypeLabel(_shiftType),
      shiftHours: hoursVal.isNotEmpty ? hoursVal : '-',
      rate: rateVal,
      notes: notesVal,
      evidenceAssetPath: _assetPhotoPath,
      evidenceLocalFilePath: _localPhotoPath,
    );

    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Edit Shift: $dateStr' : 'Tambah Absensi Shift',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tanggal Masuk',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedDate = DateTime.now()),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.today, size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Set Hari Ini (Real-Time)',
                            style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF10B981),
                            surface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getDayName(_selectedDate)}, $dateStr',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Shift Type Dropdown & Segari Rule Callout
              const Text(
                'Tipe Shift & Lembur Segari',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Aturan Lembur: Shift Reguler bisa ditambah lembur 1x MP3H. Shift MP3H bisa digabung jadi Double MP3H (Maksimal 2x MP3H per hari).',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _shiftType,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: _shiftTypes.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: _onShiftTypeChanged,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Hours and Rate
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Kerja',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final res = await showDialog<String>(
                              context: context,
                              builder: (_) => ShiftTimePickerDialog(
                                initialHours: _hoursController.text,
                              ),
                            );
                            if (res != null) {
                              setState(() => _hoursController.text = res);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: TextFormField(
                            controller: _hoursController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: '09:00 - 18:00',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                              ),
                              suffixIcon: const Icon(Icons.access_time_filled, color: Color(0xFF10B981), size: 18),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upah (Rp)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                          decoration: InputDecoration(
                            hintText: '120000',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notes
              const Text(
                'Catatan Khusus / Keterangan',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'contoh: SO Global, Bongkar Muat, Lembur',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Photo Evidence Picker
              const Text(
                'Lampirkan Foto Bukti (Jadwal / Absen)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_localPhotoPath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_localPhotoPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk untuk mengganti foto',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                        ),
                      ] else if (_assetPhotoPath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _assetPhotoPath!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk untuk mengganti foto',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                        ),
                      ] else ...[
                        const Icon(Icons.add_a_photo, size: 36, color: Color(0xFF10B981)),
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk untuk ambil foto kamera / galeri',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF064E3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditing ? 'Simpan Perubahan' : 'Simpan Data Absensi',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
