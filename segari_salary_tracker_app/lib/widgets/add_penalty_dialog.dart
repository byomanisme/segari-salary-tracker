import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/penalty_model.dart';
import '../models/user_settings.dart';

class AddPenaltyDialog extends StatefulWidget {
  final UserSettings settings;
  final Function(ComplaintPenalty) onSave;

  const AddPenaltyDialog({
    Key? key,
    required this.settings,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddPenaltyDialog> createState() => _AddPenaltyDialogState();
}

class _AddPenaltyDialogState extends State<AddPenaltyDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late String _penaltyType;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _penaltyType = 'barang_kurang';
    _amountController = TextEditingController(text: widget.settings.penaltyLessItem.toString());
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _penaltyType = newType;
      if (newType == 'barang_kurang') {
        _amountController.text = widget.settings.penaltyLessItem.toString();
      } else if (newType == 'sku_busuk') {
        _amountController.text = widget.settings.penaltyRottenSku.toString();
      }
    });
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'barang_kurang':
        return 'Barang Kurang (Missing Item)';
      case 'sku_busuk':
        return 'SKU Busuk / Rusak / Expired';
      case 'custom':
        return 'Komplain Lainnya';
      default:
        return 'Komplain Customer';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final penalty = ComplaintPenalty(
      id: 'penalty_${DateTime.now().millisecondsSinceEpoch}',
      date: dateStr,
      type: _penaltyType,
      typeLabel: _getTypeLabel(_penaltyType),
      amount: amount,
      notes: _notesController.text.trim(),
    );

    widget.onSave(penalty);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.report_problem_outlined, color: Color(0xFFEF4444), size: 20),
          SizedBox(width: 8),
          Text('Catat Denda Komplain', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jenis Komplain', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _penaltyType,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(
                        value: 'barang_kurang',
                        child: Text('Barang Kurang (Rp 10.000)'),
                      ),
                      DropdownMenuItem(
                        value: 'sku_busuk',
                        child: Text('SKU Busuk / Rusak (Rp 50.000)'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Nominal Kustom / Lainnya'),
                      ),
                    ],
                    onChanged: _onTypeChanged,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text('Tanggal Kejadian', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
                        colorScheme: const ColorScheme.dark(primary: Color(0xFFEF4444), surface: Color(0xFF1E293B)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text('Nominal Denda (Rp)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                decoration: InputDecoration(
                  hintText: '10000',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 12),

              const Text('Nomor Order / Keterangan', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'contoh: Order #SEG-9871 (Apel Fuji)',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: _save,
          child: const Text('Simpan Denda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
