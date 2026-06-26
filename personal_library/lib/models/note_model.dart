class NoteModel {
  final String id;
  final String nguoiDungId;
  final String sachId;
  final int soTrang;
  final String noiDung;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.nguoiDungId,
    required this.sachId,
    required this.soTrang,
    required this.noiDung,
    this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? '',
      nguoiDungId: json['nguoi_dung_id'] ?? '',
      sachId: json['sach_id'] ?? '',
      soTrang: json['so_trang'] ?? 0,
      noiDung: json['noi_dung'] ?? '',
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
      'so_trang': soTrang,
      'noi_dung': noiDung,
    };
  }

  NoteModel copyWith({
    String? noiDung,
    int? soTrang,
  }) {
    return NoteModel(
      id: id,
      nguoiDungId: nguoiDungId,
      sachId: sachId,
      soTrang: soTrang ?? this.soTrang,
      noiDung: noiDung ?? this.noiDung,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}