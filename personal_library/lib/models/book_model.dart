class BookModel {
  final String id;
  final String tieuDe;
  final String tacGia;
  final String? anhBia;
  final String? fileUrl;
  final String? loaiFile;
  final String? moTa;
  final int? namXuatBan;
  final int? tongSoTrang;
  final String? categoryId;      // ✅ Thêm
  final String? categoryName;    // ✅ Thêm

  BookModel({
    required this.id,
    required this.tieuDe,
    required this.tacGia,
    this.anhBia,
    this.fileUrl,
    this.loaiFile,
    this.moTa,
    this.namXuatBan,
    this.tongSoTrang,
    this.categoryId,             // ✅ Thêm
    this.categoryName,           // ✅ Thêm
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Lấy thông tin thể loại từ response
    final theLoai = json['the_loai'] as Map<String, dynamic>?;
    
    return BookModel(
      id: json['id'] ?? '',
      tieuDe: json['tieu_de'] ?? '',
      tacGia: json['tac_gia'] ?? '',
      anhBia: json['anh_bia'],
      fileUrl: json['file_url'],
      loaiFile: json['loai_file'],
      moTa: json['mo_ta'],
      namXuatBan: json['nam_xuat_ban'],
      tongSoTrang: json['tong_so_trang'],
      categoryId: theLoai?['id'],           // ✅ Thêm
      categoryName: theLoai?['ten_the_loai'], // ✅ Thêm
    );
  }
}