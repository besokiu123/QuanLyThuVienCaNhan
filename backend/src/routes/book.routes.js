const express = require('express');
const router = express.Router();

const upload = require('../middlewares/upload.middleware');
const bookController = require('../controllers/book.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const roleMiddleware = require('../middlewares/role.middleware');

// Danh sách sách
router.get('/', bookController.getDanhSachSach);

// 🔥 Lấy sách đang đọc
router.get('/reading', authMiddleware, bookController.getReadingBooks);

// 🔥 Lấy sách đã đọc
router.get('/completed', authMiddleware, bookController.getCompletedBooks);

// Tìm kiếm và lọc sách
router.get('/search', authMiddleware, bookController.getAll);

// Chi tiết sách
router.get('/:id', bookController.getChiTietSach);

// Thêm sách
router.post(
    '/',
    authMiddleware,
    roleMiddleware('THU_THU'),
    upload.fields([
        { name: 'anh_bia', maxCount: 1 },
        { name: 'file_sach', maxCount: 1 }
    ]),
    bookController.addSach
);

// Cập nhật sách
router.patch(
    '/:id',
    authMiddleware,
    roleMiddleware('THU_THU'),
    upload.fields([
        { name: 'anh_bia', maxCount: 1 },
        { name: 'file_sach', maxCount: 1 }
    ]),
    bookController.updateSach
);

// Xóa sách
router.delete(
    '/:id',
    authMiddleware,
    roleMiddleware('THU_THU'),
    bookController.deleteSach
);
router.get('/signed-url/:bookId', authMiddleware, bookController.getSignedUrl);

module.exports = router;