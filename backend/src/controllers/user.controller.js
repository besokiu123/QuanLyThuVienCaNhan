const userService = require('../services/user.service');

// ================= GET PROFILE =================
exports.getProfile = async (req, res) => {
    try {
        const user = await userService.getUserById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy người dùng' });
        }

        res.status(200).json({
            success: true,
            data: {
                id: user.id,
                email: user.email,
                ten_hien_thi: user.ten_hien_thi,
                anh_dai_dien: user.anh_dai_dien,
                vai_tro: user.vai_tro,
                trang_thai: user.trang_thai,
                created_at: user.created_at
            }
        });
    } catch (error) {
        console.error('❌ Get profile error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= UPDATE PROFILE =================
exports.updateProfile = async (req, res) => {
    try {
        const { ten_hien_thi, anh_dai_dien } = req.body;

        if (!ten_hien_thi || ten_hien_thi.trim() === '') {
            return res.status(400).json({ message: 'Tên hiển thị không được để trống' });
        }

        const user = await userService.updateProfile(req.user.id, {
            ten_hien_thi: ten_hien_thi.trim(),
            anh_dai_dien: anh_dai_dien || null
        });

        res.status(200).json({
            success: true,
            message: 'Cập nhật thông tin thành công',
            data: {
                id: user.id,
                email: user.email,
                ten_hien_thi: user.ten_hien_thi,
                anh_dai_dien: user.anh_dai_dien,
                vai_tro: user.vai_tro
            }
        });
    } catch (error) {
        console.error('❌ Update profile error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= CHANGE PASSWORD =================
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Mật khẩu mới phải có ít nhất 6 ký tự' });
        }

        await userService.changePassword(req.user.id, currentPassword, newPassword);

        res.status(200).json({
            success: true,
            message: 'Đổi mật khẩu thành công'
        });
    } catch (error) {
        console.error('❌ Change password error:', error);
        res.status(400).json({ message: error.message });
    }
};

// ================= UPLOAD AVATAR =================
exports.uploadAvatar = async (req, res) => {
    try {
        // Giả định bạn đã dùng multer để upload file
        if (!req.file) {
            return res.status(400).json({ message: 'Vui lòng chọn ảnh' });
        }

        // Upload lên Cloudinary
        const cloudinary = require('../config/cloudinary');
        const streamifier = require('streamifier');

        const result = await new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: 'avatars' },
                (error, result) => {
                    if (error) return reject(error);
                    resolve(result);
                }
            );
            streamifier.createReadStream(req.file.buffer).pipe(stream);
        });

        // Cập nhật ảnh đại diện
        const user = await userService.updateProfile(req.user.id, {
            anh_dai_dien: result.secure_url
        });

        res.status(200).json({
            success: true,
            message: 'Upload ảnh thành công',
            data: {
                avatar_url: result.secure_url
            }
        });
    } catch (error) {
        console.error('❌ Upload avatar error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= GET ALL USERS (ADMIN) =================
exports.getAllUsers = async (req, res) => {
    try {
        // Chỉ cho THU_THU
        if (req.user.vai_tro !== 'THU_THU') {
            return res.status(403).json({ message: 'Không có quyền truy cập' });
        }

        const users = await userService.getAllUsers();
        res.status(200).json({
            success: true,
            data: users.map(user => ({
                id: user.id,
                email: user.email,
                ten_hien_thi: user.ten_hien_thi,
                anh_dai_dien: user.anh_dai_dien,
                vai_tro: user.vai_tro,
                trang_thai: user.trang_thai,
                created_at: user.created_at
            }))
        });
    } catch (error) {
        console.error('❌ Get all users error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= UPDATE USER ROLE (ADMIN) =================
exports.updateUserRole = async (req, res) => {
    try {
        const { userId } = req.params;
        const { vai_tro } = req.body;

        if (req.user.vai_tro !== 'THU_THU') {
            return res.status(403).json({ message: 'Không có quyền truy cập' });
        }

        if (!vai_tro || !['DOC_GIA', 'THU_THU'].includes(vai_tro)) {
            return res.status(400).json({ message: 'Vai trò không hợp lệ' });
        }

        const user = await userService.updateUserRole(userId, vai_tro);
        res.status(200).json({
            success: true,
            message: 'Cập nhật vai trò thành công',
            data: {
                id: user.id,
                ten_hien_thi: user.ten_hien_thi,
                vai_tro: user.vai_tro
            }
        });
    } catch (error) {
        console.error('❌ Update user role error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= DELETE USER (ADMIN) =================
exports.deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;

        if (req.user.vai_tro !== 'THU_THU') {
            return res.status(403).json({ message: 'Không có quyền truy cập' });
        }

        // Không cho xóa chính mình
        if (userId === req.user.id) {
            return res.status(400).json({ message: 'Không thể xóa tài khoản của chính mình' });
        }

        await userService.deleteUser(userId);
        res.status(200).json({
            success: true,
            message: 'Xóa người dùng thành công'
        });
    } catch (error) {
        console.error('❌ Delete user error:', error);
        res.status(500).json({ message: error.message });
    }
};