// reading_progress_model.dart
class ReadingProgressModel {
  final int trangHienTai;
  final String? epubCfi;
  final int phanTramTienDo;
  final String trangThai;
  final DateTime? ngayBatDau;
  final DateTime? ngayHoanThanh;
  final DateTime? updatedAt;

  ReadingProgressModel({
    required this.trangHienTai,
    this.epubCfi,
    required this.phanTramTienDo,
    required this.trangThai,
    this.ngayBatDau,
    this.ngayHoanThanh,
    this.updatedAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      trangHienTai: json['trang_hien_tai'] ?? 0,
      epubCfi: json['epubCfi'],
      phanTramTienDo: json['phan_tram_tien_do'] ?? 0,
      trangThai: json['trang_thai'] ?? 'CHUA_DOC',
      ngayBatDau: json['ngay_bat_dau'] != null ? DateTime.parse(json['ngay_bat_dau']) : null,
      ngayHoanThanh: json['ngay_hoan_thanh'] != null ? DateTime.parse(json['ngay_hoan_thanh']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}