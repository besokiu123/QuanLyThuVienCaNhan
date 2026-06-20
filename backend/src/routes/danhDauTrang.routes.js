const express=require('express');
const router=express.Router();
const danhDauTrangController=require('../controllers/danhDauTrang.controller');
const authMiddleware=require('../middlewares/auth.middleware');

// Thêm đánh dấu trang
router.post('/add', authMiddleware, danhDauTrangController.add);
// Lấy danh sách đánh dấu trang của một cuốn sách
router.get('/book/:bookId', authMiddleware, danhDauTrangController.getAllByBook);
// Xóa đánh dấu trang
router.delete('/delete/:id', authMiddleware, danhDauTrangController.remove);

module.exports=router;