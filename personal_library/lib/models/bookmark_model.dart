class BookmarkModel {
  final String id;
  final String nguoiDungId;
  final String sachId;
  final int soTrang;
  final DateTime? createdAt;

  BookmarkModel({
    required this.id,
    required this.nguoiDungId,
    required this.sachId,
    required this.soTrang,
    this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] ?? '',
      nguoiDungId: json['nguoi_dung_id'] ?? '',
      sachId: json['sach_id'] ?? '',
      soTrang: json['so_trang'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'sach_id': sachId,
      'so_trang': soTrang,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}