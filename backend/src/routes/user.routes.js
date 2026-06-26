const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const roleMiddleware = require('../middlewares/role.middleware');
const upload = require('../middlewares/upload.middleware');

// Tất cả routes cần xác thực
router.use(authMiddleware);

// Lấy thông tin cá nhân
router.get('/profile', userController.getProfile);

// Cập nhật thông tin cá nhân
router.put('/profile', userController.updateProfile);

// Đổi mật khẩu
router.post('/change-password', userController.changePassword);

// Upload ảnh đại diện
router.post('/upload-avatar', upload.single('avatar'), userController.uploadAvatar);

// ====== ADMIN ONLY ======
// Lấy danh sách người dùng (chỉ THU_THU)
router.get('/', roleMiddleware('THU_THU'), userController.getAllUsers);

// Cập nhật vai trò (chỉ THU_THU)
router.patch('/:userId/role', roleMiddleware('THU_THU'), userController.updateUserRole);

// Xóa người dùng (chỉ THU_THU)
router.delete('/:userId', roleMiddleware('THU_THU'), userController.deleteUser);

module.exports = router;