const prisma = require('../config/prisma');

// Thêm đánh dấu trang
exports.createBookmark = async (userId, bookId, soTrang) => {
    return await prisma.danh_dau_trang.create({
        data: { nguoi_dung_id: userId, sach_id: bookId, so_trang: soTrang }
    });
};

// Lấy danh sách đánh dấu trang của một cuốn sách
exports.getBookmarksByBook = async (userId, bookId) => {
    return await prisma.danh_dau_trang.findMany({
        where: { nguoi_dung_id: userId, sach_id: bookId },
        orderBy: { so_trang: 'asc' }
    });
};

// Xóa đánh dấu trang
exports.deleteBookmark = async (bookmarkId, userId) => {
    return await prisma.danh_dau_trang.deleteMany({
        where: { id: bookmarkId, nguoi_dung_id: userId }
    });
};