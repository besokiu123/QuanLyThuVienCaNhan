import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../core/storage/auth_storage.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() {
    print('📱 ===== UserManagementScreen CREATED =====');
    return _UserManagementScreenState();
  }
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _currentUserId;

@override
void initState() {
  super.initState();
  print('🔄 UserManagementScreen initState called');
  _loadCurrentUser();
  _loadUsers();
}

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getProfile();
      _currentUserId = user.id;
    } catch (e) {
      debugPrint('❌ Load current user error: $e');
    }
  }



Future<void> _loadUsers() async {
  print('📤 Loading users...');
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final users = await _userService.getAllUsers();
    print('📌 Users loaded: ${users.length}');
    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  } catch (e) {
    print('❌ Load users error: $e');
    setState(() {
      _errorMessage = e.toString();
      _isLoading = false;
    });
  }
}

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.tenHienThi
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _changeRole(UserModel user) async {
    final newRole = user.vaiTro == 'THU_THU' ? 'DOC_GIA' : 'THU_THU';
    final roleName = newRole == 'THU_THU' ? 'Thủ thư' : 'Độc giả';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xác nhận'),
        content: Text(
          'Bạn có chắc muốn đổi vai trò của "${user.tenHienThi}" thành $roleName không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5D4E),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.updateUserRole(
          userId: user.id,
          vaiTro: newRole,
        );
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật vai trò thành $roleName'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    // Không cho xóa chính mình
    if (user.id == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể xóa tài khoản của chính mình'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản của "${user.tenHienThi}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa tài khoản'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người dùng...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterUsers('');
                            });
                          },
                        )
                      : null,
                ),
                onChanged: _filterUsers,
              ),
            ),
          ),

          // Danh sách
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF4A5D4E),
                        ),
                        SizedBox(height: 16),
                        Text('Đang tải danh sách...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A5D4E),
                              ),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Không tìm thấy người dùng'
                                      : 'Chưa có người dùng nào',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          const Color(0xFF4A5D4E),
                                      child: user.anhDaiDien != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: Image.network(
                                                user.anhDaiDien!,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Text(
                                                  user.tenHienThi
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              user.tenHienThi
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.tenHienThi,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            user.email,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: user.vaiTro == 'THU_THU'
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.green.withOpacity(
                                                      0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.vaiTro == 'THU_THU'
                                                  ? 'Thủ thư'
                                                  : 'Độc giả',
                                              style: TextStyle(
                                                color: user.vaiTro == 'THU_THU'
                                                    ? Colors.blue[700]
                                                    : Colors.green[700],
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    Row(
                                      children: [
                                        // Nút đổi vai trò
                                        IconButton(
                                          icon: Icon(
                                            Icons.swap_horiz,
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                          onPressed: () => _changeRole(user),
                                          tooltip: 'Đổi vai trò',
                                        ),
                                        // Nút xóa
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[400],
                                            size: 20,
                                          ),
                                          onPressed: user.id == _currentUserId
                                              ? null
                                              : () => _deleteUser(user),
                                          tooltip: user.id == _currentUserId
                                              ? 'Không thể xóa chính mình'
                                              : 'Xóa tài khoản',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}