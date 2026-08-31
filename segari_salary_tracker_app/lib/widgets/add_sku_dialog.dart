import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sku_entry_model.dart';

class AddSkuDialog extends StatefulWidget {
  final Function(SkuEntry) onSave;

  const AddSkuDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  State<AddSkuDialog> createState() => _AddSkuDialogState();
}

class _AddSkuDialogState extends State<AddSkuDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _countController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _countController = TextEditingController();
    _notesController = TextEditingController(text: 'Picking & Packing');
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final count = int.tryParse(_countController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final entry = SkuEntry(
      id: 'sku_${DateTime.now().millisecondsSinceEpoch}',
      date: dateStr,
      count: count,
      notes: _notesController.text.trim(),
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
      title: const Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFF38BDF8), size: 20),
          SizedBox(width: 8),
          Text('Input Jumlah SKU', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanggal Kerja', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
                      colorScheme: const ColorScheme.dark(primary: Color(0xFF0284C7), surface: Color(0xFF1E293B)),
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
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF38BDF8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Jumlah SKU Selesai', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              decoration: InputDecoration(
                hintText: 'contoh: 650',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Keterangan / Posisi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'contoh: Picking Shift Pagi',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
          onPressed: _save,
          child: const Text('Simpan SKU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
