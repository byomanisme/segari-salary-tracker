import 'dart:convert';

class AttendanceRecord {
  final String id;
  final String date; // YYYY-MM-DD
  final String dayName;
  final String type; // 'reguler', 'mp3', 'reguler_mp3', 'training', 'off'
  final String typeLabel;
  final String shiftHours;
  final int rate;
  final String notes;
  final String? evidenceAssetPath;
  final String? evidenceLocalFilePath;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.dayName,
    required this.type,
    required this.typeLabel,
    required this.shiftHours,
    required this.rate,
    this.notes = '',
    this.evidenceAssetPath,
    this.evidenceLocalFilePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AttendanceRecord copyWith({
    String? id,
    String? date,
    String? dayName,
    String? type,
    String? typeLabel,
    String? shiftHours,
    int? rate,
    String? notes,
    String? evidenceAssetPath,
    String? evidenceLocalFilePath,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      dayName: dayName ?? this.dayName,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      shiftHours: shiftHours ?? this.shiftHours,
      rate: rate ?? this.rate,
      notes: notes ?? this.notes,
      evidenceAssetPath: evidenceAssetPath ?? this.evidenceAssetPath,
      evidenceLocalFilePath: evidenceLocalFilePath ?? this.evidenceLocalFilePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'dayName': dayName,
      'type': type,
      'typeLabel': typeLabel,
      'shiftHours': shiftHours,
      'rate': rate,
      'notes': notes,
      'evidenceAssetPath': evidenceAssetPath,
      'evidenceLocalFilePath': evidenceLocalFilePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      dayName: map['dayName'] ?? '',
      type: map['type'] ?? 'reguler',
      typeLabel: map['typeLabel'] ?? '',
      shiftHours: map['shiftHours'] ?? '-',
      rate: map['rate'] is int ? map['rate'] : int.tryParse(map['rate'].toString()) ?? 0,
      notes: map['notes'] ?? '',
      evidenceAssetPath: map['evidenceAssetPath'],
      evidenceLocalFilePath: map['evidenceLocalFilePath'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceRecord.fromJson(String source) =>
      AttendanceRecord.fromMap(json.decode(source));
}
