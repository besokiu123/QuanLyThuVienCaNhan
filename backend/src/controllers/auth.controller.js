const authService = require('../services/auth.service');

// ĐĂNG KÝ
exports.register = async (req, res, next) => {
    try {
const { email, password, ten_hien_thi } = req.body;        
        if (!email || !password || !ten_hien_thi) {
            return res.status(400).json({ message: "Vui lòng điền đầy đủ thông tin" });
        }

const newUser = await authService.register(
    email,
    password,
    ten_hien_thi
);        
        // Chỉ trả về thông tin cần thiết, KHÔNG TRẢ VỀ mat_khau_hash
        res.status(201).json({
            message: "Đăng ký thành công",
            user: {
                id: newUser.id,
                email: newUser.email,
                ten_hien_thi: newUser.ten_hien_thi
            }
        });
    } catch (error) {
        // Nếu lỗi do email tồn tại, trả về 400
        res.status(400).json({ message: error.message });
    }
};

// ĐĂNG NHẬP
exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        const result = await authService.login(email, password);
        
        res.status(200).json({
            message: 'Đăng nhập thành công!',
            data: result
        });
    } catch (error) {
        res.status(401).json({ message: error.message });
    }
};