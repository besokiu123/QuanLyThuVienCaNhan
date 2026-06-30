class ReviewModel {
  final String id;
  final String nguoiDungId;
  final String sachId;
  final int soSao;
  final String nhanXet;
  final String? tenHienThi;
  final String? anhDaiDien;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.nguoiDungId,
    required this.sachId,
    required this.soSao,
    required this.nhanXet,
    this.tenHienThi,
    this.anhDaiDien,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Lấy thông tin người dùng từ nested object
    final nguoiDung = json['nguoi_dung'] as Map<String, dynamic>?;
    
    return ReviewModel(
      id: json['id'] ?? '',
      nguoiDungId: json['nguoi_dung_id'] ?? '',
      sachId: json['sach_id'] ?? '',
      soSao: json['so_sao'] ?? 0,
      nhanXet: json['nhan_xet'] ?? '',
      tenHienThi: nguoiDung?['ten_hien_thi'] ?? '',
      anhDaiDien: nguoiDung?['anh_dai_dien'],
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
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'sach_id': sachId,
      'so_sao': soSao,
      'nhan_xet': nhanXet,
    };
  }
}