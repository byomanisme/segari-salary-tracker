import 'package:flutter/material.dart';
import '../models/user_settings.dart';

class EditSkuCommissionDialog extends StatefulWidget {
  final UserSettings settings;
  final Function(UserSettings) onSave;

  const EditSkuCommissionDialog({
    Key? key,
    required this.settings,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditSkuCommissionDialog> createState() => _EditSkuCommissionDialogState();
}

class _EditSkuCommissionDialogState extends State<EditSkuCommissionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _s1TargetCtrl;
  late TextEditingController _s1BonusCtrl;
  late TextEditingController _s2TargetCtrl;
  late TextEditingController _s2BonusCtrl;
  late TextEditingController _s3TargetCtrl;
  late TextEditingController _s3BonusCtrl;

  @override
  void initState() {
    super.initState();
    _s1TargetCtrl = TextEditingController(text: widget.settings.severity1Target.toString());
    _s1BonusCtrl = TextEditingController(text: widget.settings.severity1Bonus.toString());
    _s2TargetCtrl = TextEditingController(text: widget.settings.severity2Target.toString());
    _s2BonusCtrl = TextEditingController(text: widget.settings.severity2Bonus.toString());
    _s3TargetCtrl = TextEditingController(text: widget.settings.severity3Target.toString());
    _s3BonusCtrl = TextEditingController(text: widget.settings.severity3Bonus.toString());
  }

  @override
  void dispose() {
    _s1TargetCtrl.dispose();
    _s1BonusCtrl.dispose();
    _s2TargetCtrl.dispose();
    _s2BonusCtrl.dispose();
    _s3TargetCtrl.dispose();
    _s3BonusCtrl.dispose();
    super.dispose();
  }

  void _resetToDefault() {
    setState(() {
      _s1TargetCtrl.text = '13500';
      _s1BonusCtrl.text = '400000';
      _s2TargetCtrl.text = '15500';
      _s2BonusCtrl.text = '500000';
      _s3TargetCtrl.text = '17500';
      _s3BonusCtrl.text = '600000';
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.settings.copyWith(
      severity1Target: int.tryParse(_s1TargetCtrl.text) ?? 13500,
      severity1Bonus: int.tryParse(_s1BonusCtrl.text) ?? 400000,
      severity2Target: int.tryParse(_s2TargetCtrl.text) ?? 15500,
      severity2Bonus: int.tryParse(_s2BonusCtrl.text) ?? 500000,
      severity3Target: int.tryParse(_s3TargetCtrl.text) ?? 17500,
      severity3Bonus: int.tryParse(_s3BonusCtrl.text) ?? 600000,
    );

    widget.onSave(updated);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Tarif komisi & target SKU berhasil diperbarui!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Komisi & Target SKU',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sesuaikan nominal bonus & target bulanan',
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

              // Severity 1 Box
              _buildSeverityBox(
                title: 'Severity 1 (Target Utama)',
                icon: Icons.looks_one,
                color: const Color(0xFF10B981),
                targetCtrl: _s1TargetCtrl,
                bonusCtrl: _s1BonusCtrl,
              ),

              const SizedBox(height: 12),

              // Severity 2 Box
              _buildSeverityBox(
                title: 'Severity 2 (Target Menengah)',
                icon: Icons.looks_two,
                color: const Color(0xFF38BDF8),
                targetCtrl: _s2TargetCtrl,
                bonusCtrl: _s2BonusCtrl,
              ),

              const SizedBox(height: 12),

              // Severity 3 Box
              _buildSeverityBox(
                title: 'Severity 3 (Target Maksimal 🔥)',
                icon: Icons.looks_3,
                color: const Color(0xFFF59E0B),
                targetCtrl: _s3TargetCtrl,
                bonusCtrl: _s3BonusCtrl,
              ),

              const SizedBox(height: 16),

              // Reset default link
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 14, color: Color(0xFF94A3B8)),
                  label: const Text(
                    'Reset ke Standar (13.5k/400rb, 15.5k/500rb, 17.5k/600rb)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  onPressed: _resetToDefault,
                ),
              ),

              const SizedBox(height: 12),

              // Actions
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
                    label: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBox({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController targetCtrl,
    required TextEditingController bonusCtrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  decoration: InputDecoration(
                    labelText: 'Target SKU',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    suffixText: 'SKU',
                    suffixStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: bonusCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.bold),
                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  decoration: InputDecoration(
                    labelText: 'Bonus Komisi',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    suffixText: 'Rp',
                    suffixStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
