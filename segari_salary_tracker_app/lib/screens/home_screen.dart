import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../services/update_service.dart';
import '../widgets/salary_hero_card.dart';
import '../widgets/segari_contribution_grid.dart';
import '../widgets/sku_target_card.dart';
import '../widgets/complaint_penalty_card.dart';
import '../widgets/add_sku_dialog.dart';
import '../widgets/add_penalty_dialog.dart';
import '../widgets/update_dialog.dart';
import '../widgets/whatsapp_dialog.dart';
import 'pdf_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserSettings settings;
  final List<AttendanceRecord> records;
  final List<ComplaintPenalty> penalties;
  final List<SkuEntry> skuEntries;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenAddShift;
  final VoidCallback onOpenHistory;
  final Function(SkuEntry)? onAddSku;
  final Function(SkuEntry)? onDeleteSku;
  final Function(ComplaintPenalty)? onAddPenalty;
  final Function(ComplaintPenalty)? onDeletePenalty;
  final Function(UserSettings)? onUpdateSettings;

  const HomeScreen({
    Key? key,
    required this.settings,
    required this.records,
    required this.penalties,
    required this.skuEntries,
    required this.onRefresh,
    required this.onOpenAddShift,
    required this.onOpenHistory,
    this.onAddSku,
    this.onDeleteSku,
    this.onAddPenalty,
    this.onDeletePenalty,
    this.onUpdateSettings,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _checkVersionAndUpdates();
    });
  }

  Future<void> _checkVersionAndUpdates() async {
    // 1. If user just updated to a new version, show What's New dialog on homescreen!
    final showWhatsNew = await _updateService.shouldShowWhatsNew();
    if (showWhatsNew && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WhatsNewDialog(
          onDismiss: () {
            _updateService.markWhatsNewSeen();
          },
        ),
      );
    }

    // 2. Check if a newer version is available from remote server
    final updateInfo = await _updateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateAvailableDialog(
          updateInfo: updateInfo,
          onSnooze: () {
            _updateService.snoozeUpdateForTomorrow();
          },
          onUpdate: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => InAppDownloadProgressDialog(
                downloadUrl: updateInfo.downloadUrl,
                version: updateInfo.version,
              ),
            );
          },
        ),
      );
    }
  }

  void _showWhatsAppDialog(BuildContext context) {
    final now = DateTime.now();
    final currentCycleKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    showDialog(
      context: context,
      builder: (_) => WhatsAppDialog(
        settings: widget.settings,
        records: widget.records,
        penalties: widget.penalties,
        skuEntries: widget.skuEntries,
        initialCycleKey: currentCycleKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentCycleKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonthSkuEntries = widget.skuEntries.where((e) => e.date.startsWith(currentCycleKey)).toList();
    final currentMonthPenalties = widget.penalties.where((p) => p.date.startsWith(currentCycleKey)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesaat Apps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.settings.name} • ${widget.settings.empId}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // WhatsApp Share Button
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF25D366)),
            tooltip: 'Kirim Format WA Leader',
            onPressed: () => _showWhatsAppDialog(context),
          ),
          // PDF Export Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
            tooltip: 'Cetak Slip Gaji PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfPreviewScreen(
                    settings: widget.settings,
                    records: widget.records,
                    penalties: widget.penalties,
                    skuEntries: widget.skuEntries,
                    initialCycleKey: currentCycleKey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Take Home Pay Hero Card with Fruit Watermark & Multi-Tier Severity
              SalaryHeroCard(
                records: widget.records,
                skuEntries: widget.skuEntries,
                penalties: widget.penalties,
                settings: widget.settings,
              ),

              const SizedBox(height: 16),

              // 2. Interactive Segari Contribution Matrix
              SegariContributionGrid(
                records: widget.records,
                penalties: widget.penalties,
                skuEntries: widget.skuEntries,
              ),

              const SizedBox(height: 16),

              // 3. Multi-Tier SKU Target Card (Filtered to Current Month)
              SkuTargetCard(
                settings: widget.settings,
                skuEntries: currentMonthSkuEntries,
                onUpdateSettings: widget.onUpdateSettings,
                onAddSku: () {
                  if (widget.onAddSku != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AddSkuDialog(
                        onSave: widget.onAddSku!,
                        existingSkuEntries: widget.skuEntries,
                        activeCycleKey: currentCycleKey,
                      ),
                    );
                  }
                },
                onDeleteSku: (entry) {
                  if (widget.onDeleteSku != null) {
                    widget.onDeleteSku!(entry);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 4. Complaint Penalties Card (Filtered to Current Month)
              ComplaintPenaltyCard(
                settings: widget.settings,
                penalties: currentMonthPenalties,
                onAddPenalty: () {
                  if (widget.onAddPenalty != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AddPenaltyDialog(
                        settings: widget.settings,
                        onSave: widget.onAddPenalty!,
                      ),
                    );
                  }
                },
                onDeletePenalty: (penalty) {
                  if (widget.onDeletePenalty != null) {
                    widget.onDeletePenalty!(penalty);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Quick Actions Bar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF064E3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ Input Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: widget.onOpenAddShift,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Buka Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: widget.onOpenHistory,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
