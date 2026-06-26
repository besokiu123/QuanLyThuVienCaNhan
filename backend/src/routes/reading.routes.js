const express = require('express');
const router = express.Router();
const readingController = require('../controllers/reading.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Tất cả routes đều cần xác thực
router.use(authMiddleware);

// Lấy tiến độ đọc
router.get('/progress/:bookId', readingController.getProgress);

// Lưu tiến độ đọc
router.post('/progress', readingController.saveProgress);

// Lưu phiên đọc
router.post('/session', readingController.addReadingSession);

module.exports = router;