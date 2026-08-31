class SkuEntry {
  final String id;
  final String date;
  final int count;
  final String notes;

  SkuEntry({
    required this.id,
    required this.date,
    required this.count,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'count': count,
      'notes': notes,
    };
  }

  factory SkuEntry.fromJson(Map<String, dynamic> json) {
    return SkuEntry(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  SkuEntry copyWith({
    String? id,
    String? date,
    int? count,
    String? notes,
  }) {
    return SkuEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      count: count ?? this.count,
      notes: notes ?? this.notes,
    );
  }
}
