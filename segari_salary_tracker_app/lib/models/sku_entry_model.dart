class SkuEntry {
  final String id;
  final String date;
  final int count;
  final String notes;
  final int? cumulativeTotal;
  final String? avgPicking;
  final String? speedTime;

  SkuEntry({
    required this.id,
    required this.date,
    required this.count,
    required this.notes,
    this.cumulativeTotal,
    this.avgPicking,
    this.speedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'count': count,
      'notes': notes,
      if (cumulativeTotal != null) 'cumulativeTotal': cumulativeTotal,
      if (avgPicking != null) 'avgPicking': avgPicking,
      if (speedTime != null) 'speedTime': speedTime,
    };
  }

  factory SkuEntry.fromJson(Map<String, dynamic> json) {
    return SkuEntry(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      cumulativeTotal: (json['cumulativeTotal'] as num?)?.toInt(),
      avgPicking: json['avgPicking'] as String?,
      speedTime: json['speedTime'] as String?,
    );
  }

  SkuEntry copyWith({
    String? id,
    String? date,
    int? count,
    String? notes,
    int? cumulativeTotal,
    String? avgPicking,
    String? speedTime,
  }) {
    return SkuEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      cumulativeTotal: cumulativeTotal ?? this.cumulativeTotal,
      avgPicking: avgPicking ?? this.avgPicking,
      speedTime: speedTime ?? this.speedTime,
    );
  }
}
