// services/user.service.js
const prisma = require('../config/prisma');
const bcrypt = require('bcrypt');

// ================= GET USER BY ID =================
exports.getUserById = async (userId) => {
    return await prisma.nguoi_dung.findUnique({
        where: { id: userId },
        select: {
            id: true,
            email: true,
            ten_hien_thi: true,
            anh_dai_dien: true,
            vai_tro: true,
            trang_thai: true,
            created_at: true,
            updated_at: true
        }
    });
};

// ================= UPDATE PROFILE =================
exports.updateProfile = async (userId, data) => {
    return await prisma.nguoi_dung.update({
        where: { id: userId },
        data: {
            ten_hien_thi: data.ten_hien_thi,
            anh_dai_dien: data.anh_dai_dien,
            updated_at: new Date()
        },
        select: {
            id: true,
            email: true,
            ten_hien_thi: true,
            anh_dai_dien: true,
            vai_tro: true
        }
    });
};

// ================= CHANGE PASSWORD =================
exports.changePassword = async (userId, currentPassword, newPassword) => {
    const user = await prisma.nguoi_dung.findUnique({
        where: { id: userId },
        select: { mat_khau_hash: true }
    });

    if (!user) {
        throw new Error('Không tìm thấy người dùng');
    }

    const isMatch = await bcrypt.compare(currentPassword, user.mat_khau_hash);
    if (!isMatch) {
        throw new Error('Mật khẩu hiện tại không đúng');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.nguoi_dung.update({
        where: { id: userId },
        data: {
            mat_khau_hash: hashedPassword,
            updated_at: new Date()
        }
    });
};

// ================= GET ALL USERS =================
exports.getAllUsers = async () => {  // 🔥 KHÔNG CÓ req, res
    console.log('🔍 getAllUsers called');
    
    const users = await prisma.nguoi_dung.findMany({
        select: {
            id: true,
            email: true,
            ten_hien_thi: true,
            anh_dai_dien: true,
            vai_tro: true,
            trang_thai: true,
            created_at: true,
            updated_at: true
        },
        orderBy: { created_at: 'desc' }
    });
    
    console.log(`✅ Found ${users.length} users`);
    return users;
};

// ================= UPDATE USER ROLE =================
exports.updateUserRole = async (userId, vaiTro) => {
    return await prisma.nguoi_dung.update({
        where: { id: userId },
        data: {
            vai_tro: vaiTro,
            updated_at: new Date()
        },
        select: {
            id: true,
            ten_hien_thi: true,
            vai_tro: true
        }
    });
};

// ================= DELETE USER =================
exports.deleteUser = async (userId) => {
    return await prisma.nguoi_dung.delete({
        where: { id: userId }
    });
};