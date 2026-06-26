class DashboardStats {
  final int totalBooks;
  final int totalUsers;
  final int newArrivals;
  final int totalReading;

  DashboardStats({
    required this.totalBooks,
    required this.totalUsers,
    this.newArrivals = 0,
    this.totalReading = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalBooks: json['totalBooks'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      newArrivals: json['newArrivals'] ?? 0,
      totalReading: json['totalReading'] ?? 0,
    );
  }
}