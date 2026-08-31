import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/penalty_model.dart';
import '../models/sku_entry_model.dart';
import '../models/user_settings.dart';
import '../data/storage_service.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'sku_penalty_screen.dart';
import 'settings_screen.dart';
import 'add_edit_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final StorageService _storageService = StorageService();

  int _currentIndex = 0;
  bool _isLoading = true;

  UserSettings _settings = UserSettings();
  List<AttendanceRecord> _records = [];
  List<ComplaintPenalty> _penalties = [];
  List<SkuEntry> _skuEntries = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final settings = await _storageService.getSettings();
    final records = await _storageService.getRecords();
    final penalties = await _storageService.getPenalties();
    final skuEntries = await _storageService.getSkuEntries();

    setState(() {
      _settings = settings;
      _records = records;
      _penalties = penalties;
      _skuEntries = skuEntries;
      _isLoading = false;
    });
  }

  Future<void> _openAddShift() async {
    final result = await Navigator.push<AttendanceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(settings: _settings),
      ),
    );

    if (result != null) {
      await _storageService.addOrUpdateRecord(result);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi shift berhasil dicatat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1120),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    final pages = [
      // Index 0: Beranda
      HomeScreen(
        settings: _settings,
        records: _records,
        penalties: _penalties,
        skuEntries: _skuEntries,
        onRefresh: _loadAllData,
        onOpenAddShift: _openAddShift,
        onOpenHistory: () => setState(() => _currentIndex = 1),
        onAddSku: (entry) async {
          await _storageService.addOrUpdateSkuEntry(entry);
          await _loadAllData();
        },
        onDeleteSku: (entry) async {
          await _storageService.deleteSkuEntry(entry.id);
          await _loadAllData();
        },
        onAddPenalty: (penalty) async {
          await _storageService.addOrUpdatePenalty(penalty);
          await _loadAllData();
        },
        onDeletePenalty: (penalty) async {
          await _storageService.deletePenalty(penalty.id);
          await _loadAllData();
        },
        onUpdateSettings: (updated) async {
          await _storageService.saveSettings(updated);
          await _loadAllData();
        },
      ),

      // Index 1: Riwayat Absensi
      HistoryScreen(
        settings: _settings,
        records: _records,
        penalties: _penalties,
        skuEntries: _skuEntries,
        onSaveRecord: (rec) async {
          await _storageService.addOrUpdateRecord(rec);
          await _loadAllData();
        },
        onDeleteRecord: (rec) async {
          await _storageService.deleteRecord(rec.id);
          await _loadAllData();
        },
        onDataRestored: _loadAllData,
      ),

      // Index 2: Target & Denda
      SkuPenaltyScreen(
        settings: _settings,
        skuEntries: _skuEntries,
        penalties: _penalties,
        onAddSku: (entry) async {
          await _storageService.addOrUpdateSkuEntry(entry);
          await _loadAllData();
        },
        onDeleteSku: (entry) async {
          await _storageService.deleteSkuEntry(entry.id);
          await _loadAllData();
        },
        onAddPenalty: (penalty) async {
          await _storageService.addOrUpdatePenalty(penalty);
          await _loadAllData();
        },
        onDeletePenalty: (penalty) async {
          await _storageService.deletePenalty(penalty.id);
          await _loadAllData();
        },
        onUpdateSettings: (updated) async {
          await _storageService.saveSettings(updated);
          await _loadAllData();
        },
      ),

      // Index 3: Pengaturan Akun
      SettingsScreen(
        settings: _settings,
        onSave: (updated) async {
          await _storageService.saveSettings(updated);
          await _loadAllData();
        },
        onResetData: () async {
          await _storageService.resetToInitial();
          await _loadAllData();
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tab 0: Beranda
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Beranda',
                ),

                // Tab 1: Riwayat (Sebelah Kanan Beranda)
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'Riwayat',
                ),

                // Center Action Button: + Tambah Shift
                InkWell(
                  onTap: _openAddShift,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Color(0xFF064E3B), size: 17),
                        SizedBox(width: 3),
                        Text(
                          'Shift',
                          style: TextStyle(
                            color: Color(0xFF064E3B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab 2: Target & Denda (Sebelah Kanan Tambah Shift)
                _buildNavItem(
                  index: 2,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Target & Denda',
                ),

                // Tab 3: Pengaturan Akun
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Akun',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
