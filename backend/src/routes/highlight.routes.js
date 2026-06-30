const express = require('express');
const router = express.Router();
const highlightController = require('../controllers/highlight.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Tất cả routes cần xác thực
router.use(authMiddleware);

// Lấy danh sách highlight của sách
router.get('/book/:bookId', highlightController.getByBook);

// Thêm highlight mới
router.post('/', highlightController.create);

// Xóa highlight
router.delete('/:id', highlightController.delete);
router.put('/:id', highlightController.update);
module.exports = router;