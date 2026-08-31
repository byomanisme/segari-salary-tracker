import 'dart:convert';

class UserSettings {
  final String name;
  final String empId;
  final int regulerRate;
  final int mp3Rate;

  // Severity Tier Milestones
  final int severity1Target;
  final int severity1Bonus;
  final int severity2Target;
  final int severity2Bonus;
  final int severity3Target;
  final int severity3Bonus;

  final int paydayDay;
  final int penaltyLessItem;
  final int penaltyRottenSku;

  UserSettings({
    this.name = 'PEKERJA SEGARI',
    this.empId = 'DW-SEGARI-001',
    this.regulerRate = 120000,
    this.mp3Rate = 50000,
    this.severity1Target = 13500,
    this.severity1Bonus = 400000,
    this.severity2Target = 15500,
    this.severity2Bonus = 500000,
    this.severity3Target = 17500,
    this.severity3Bonus = 600000,
    this.paydayDay = 6,
    this.penaltyLessItem = 10000,
    this.penaltyRottenSku = 50000,
  });

  // Backward compatibility alias for Severity 1
  int get skuTarget => severity1Target;
  int get skuBonus => severity1Bonus;

  // --- Dynamic Calculation Helpers ---
  int getBonusForSku(int totalSku) {
    if (totalSku >= severity3Target) {
      return severity3Bonus;
    } else if (totalSku >= severity2Target) {
      return severity2Bonus;
    } else if (totalSku >= severity1Target) {
      return severity1Bonus;
    }
    return 0;
  }

  int getAchievedTierLevel(int totalSku) {
    if (totalSku >= severity3Target) return 3;
    if (totalSku >= severity2Target) return 2;
    if (totalSku >= severity1Target) return 1;
    return 0;
  }

  String getSeverityTierLabel(int totalSku) {
    if (totalSku >= severity3Target) {
      return 'Severity 3 (Target Maksimal! 🔥)';
    } else if (totalSku >= severity2Target) {
      return 'Severity 2 (Target Menengah ⚡)';
    } else if (totalSku >= severity1Target) {
      return 'Severity 1 (Target Utama ✅)';
    }
    return 'Menuju Severity 1';
  }

  int getNextTarget(int totalSku) {
    if (totalSku < severity1Target) return severity1Target;
    if (totalSku < severity2Target) return severity2Target;
    return severity3Target;
  }

  int getRemainingForNextTarget(int totalSku) {
    final next = getNextTarget(totalSku);
    final diff = next - totalSku;
    return diff > 0 ? diff : 0;
  }

  UserSettings copyWith({
    String? name,
    String? empId,
    int? regulerRate,
    int? mp3Rate,
    int? severity1Target,
    int? severity1Bonus,
    int? severity2Target,
    int? severity2Bonus,
    int? severity3Target,
    int? severity3Bonus,
    int? paydayDay,
    int? penaltyLessItem,
    int? penaltyRottenSku,
  }) {
    return UserSettings(
      name: name ?? this.name,
      empId: empId ?? this.empId,
      regulerRate: regulerRate ?? this.regulerRate,
      mp3Rate: mp3Rate ?? this.mp3Rate,
      severity1Target: severity1Target ?? this.severity1Target,
      severity1Bonus: severity1Bonus ?? this.severity1Bonus,
      severity2Target: severity2Target ?? this.severity2Target,
      severity2Bonus: severity2Bonus ?? this.severity2Bonus,
      severity3Target: severity3Target ?? this.severity3Target,
      severity3Bonus: severity3Bonus ?? this.severity3Bonus,
      paydayDay: paydayDay ?? this.paydayDay,
      penaltyLessItem: penaltyLessItem ?? this.penaltyLessItem,
      penaltyRottenSku: penaltyRottenSku ?? this.penaltyRottenSku,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'empId': empId,
      'regulerRate': regulerRate,
      'mp3Rate': mp3Rate,
      'severity1Target': severity1Target,
      'severity1Bonus': severity1Bonus,
      'severity2Target': severity2Target,
      'severity2Bonus': severity2Bonus,
      'severity3Target': severity3Target,
      'severity3Bonus': severity3Bonus,
      'paydayDay': paydayDay,
      'penaltyLessItem': penaltyLessItem,
      'penaltyRottenSku': penaltyRottenSku,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      name: map['name'] as String? ?? 'PEKERJA SEGARI',
      empId: map['empId'] as String? ?? 'DW-SEGARI-001',
      regulerRate: (map['regulerRate'] as num?)?.toInt() ?? 120000,
      mp3Rate: (map['mp3Rate'] as num?)?.toInt() ?? 50000,
      severity1Target: (map['severity1Target'] as num?)?.toInt() ??
          (map['skuTarget'] as num?)?.toInt() ??
          13500,
      severity1Bonus: (map['severity1Bonus'] as num?)?.toInt() ??
          (map['skuBonus'] as num?)?.toInt() ??
          400000,
      severity2Target: (map['severity2Target'] as num?)?.toInt() ?? 15500,
      severity2Bonus: (map['severity2Bonus'] as num?)?.toInt() ?? 500000,
      severity3Target: (map['severity3Target'] as num?)?.toInt() ?? 17500,
      severity3Bonus: (map['severity3Bonus'] as num?)?.toInt() ?? 600000,
      paydayDay: (map['paydayDay'] as num?)?.toInt() ?? 6,
      penaltyLessItem: (map['penaltyLessItem'] as num?)?.toInt() ?? 10000,
      penaltyRottenSku: (map['penaltyRottenSku'] as num?)?.toInt() ?? 50000,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSettings.fromJson(String source) =>
      UserSettings.fromMap(json.decode(source));
}
