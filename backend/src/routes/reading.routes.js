const express = require('express');
const router = express.Router();
const readingController = require('../controllers/reading.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Route lưu/lấy tiến độ
router.get('/progress/:bookId', authMiddleware, readingController.getProgress);
router.post('/progress', authMiddleware, readingController.saveProgress);

// Route lưu phiên đọc
router.post('/session', authMiddleware, readingController.addReadingSession);

module.exports = router;