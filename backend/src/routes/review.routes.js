const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/review.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.post('/', authMiddleware, reviewController.saveReview); // Tạo/Sửa
router.get('/:bookId', reviewController.getByBook);            // Lấy list (không cần auth)
router.delete('/:id', authMiddleware, reviewController.remove);// Xóa

module.exports = router;