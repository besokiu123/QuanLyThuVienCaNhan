class UserModel {
  final String id;
  final String email;
  final String tenHienThi;
  final String? anhDaiDien;
  final String vaiTro;
  final bool trangThai;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.tenHienThi,
    this.anhDaiDien,
    required this.vaiTro,
    this.trangThai = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      tenHienThi: json['ten_hien_thi'] ?? '',
      anhDaiDien: json['anh_dai_dien'],
      vaiTro: json['vai_tro'] ?? 'DOC_GIA',
      trangThai: json['trang_thai'] ?? true,
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
      'email': email,
      'ten_hien_thi': tenHienThi,
      'anh_dai_dien': anhDaiDien,
      'vai_tro': vaiTro,
      'trang_thai': trangThai,
    };
  }

  UserModel copyWith({
    String? tenHienThi,
    String? anhDaiDien,
    String? vaiTro,
    bool? trangThai,
  }) {
    return UserModel(
      id: id,
      email: email,
      tenHienThi: tenHienThi ?? this.tenHienThi,
      anhDaiDien: anhDaiDien ?? this.anhDaiDien,
      vaiTro: vaiTro ?? this.vaiTro,
      trangThai: trangThai ?? this.trangThai,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}