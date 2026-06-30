class HighlightModel {
  final String id;
  final String nguoiDungId;
  final String sachId;
  final String cfi;
  final String text;
  final String color;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HighlightModel({
    required this.id,
    required this.nguoiDungId,
    required this.sachId,
    required this.cfi,
    required this.text,
    required this.color,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'] ?? '',
      nguoiDungId: json['nguoi_dung_id'] ?? '',
      sachId: json['sach_id'] ?? '',
      cfi: json['cfi'] ?? '',
      text: json['text'] ?? '',
      color: json['color'] ?? '#FFD700',
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sach_id': sachId,
      'cfi': cfi,
      'text': text,
      'color': color,
      if (note != null) 'note': note,
    };
  }

  HighlightModel copyWith({
    String? color,
    String? note,
  }) {
    return HighlightModel(
      id: id,
      nguoiDungId: nguoiDungId,
      sachId: sachId,
      cfi: cfi,
      text: text,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}