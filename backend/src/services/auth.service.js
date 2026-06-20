const prisma = require('../config/prisma');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Hàm đăng ký
exports.register = async (email, password, ten_hien_thi) => {
    if (!email || !password) throw new Error('Email và mật khẩu là bắt buộc');

    // Kiểm tra email tồn tại
    const existingUser = await prisma.nguoi_dung.findUnique({
        where: { email }
    });
    if (existingUser) {
        throw new Error('Email này đã tồn tại!');
    }

    // Hash mật khẩu
    const mat_khau_hash = await bcrypt.hash(password, 10);

    return await prisma.nguoi_dung.create({
        data: {
            email,
            mat_khau_hash,
            ten_hien_thi,
            vai_tro: 'DOC_GIA'
        }
    });
};

// Hàm đăng nhập
exports.login = async (email, password) => {
    if (!email || !password) throw new Error('Vui lòng nhập email và mật khẩu');

    const user = await prisma.nguoi_dung.findUnique({ where: { email } });
    if (!user) {
        throw new Error('Email không tồn tại!');
    }

    const isMatch = await bcrypt.compare(password, user.mat_khau_hash);
    if (!isMatch) {
        throw new Error('Mật khẩu không chính xác!');
    }

    // Tạo JWT
    const token = jwt.sign(
        { id: user.id, vai_tro: user.vai_tro },
        process.env.JWT_SECRET || 'secret_key',
        { expiresIn: '7d' }
    );

    return {
        token,
        user: {
            id: user.id,
            email: user.email,
            ten_hien_thi: user.ten_hien_thi,
            vai_tro: user.vai_tro
        }
    };
};