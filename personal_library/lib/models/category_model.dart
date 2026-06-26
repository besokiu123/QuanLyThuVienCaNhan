class CategoryModel {
  final String id;
  final String tenTheLoai;
  final String? moTa;

  CategoryModel({
    required this.id,
    required this.tenTheLoai,
    this.moTa,
  });

  factory CategoryModel.fromJson(
      Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      tenTheLoai:
          json['ten_the_loai'],
      moTa: json['mo_ta'],
    );
  }
}