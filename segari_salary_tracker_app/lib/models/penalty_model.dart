class ComplaintPenalty {
  final String id;
  final String date;
  final String type; // 'barang_kurang', 'sku_busuk', 'custom'
  final String typeLabel;
  final int amount;
  final String notes;

  ComplaintPenalty({
    required this.id,
    required this.date,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'typeLabel': typeLabel,
      'amount': amount,
      'notes': notes,
    };
  }

  factory ComplaintPenalty.fromJson(Map<String, dynamic> json) {
    return ComplaintPenalty(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'barang_kurang',
      typeLabel: json['typeLabel'] as String? ?? 'Barang Kurang',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  ComplaintPenalty copyWith({
    String? id,
    String? date,
    String? type,
    String? typeLabel,
    int? amount,
    String? notes,
  }) {
    return ComplaintPenalty(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }
}
