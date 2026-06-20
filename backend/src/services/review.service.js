const prisma = require('../config/prisma');

// Thêm đánh giá mới hoặc câp nhật đánh giá đã tồn tại
exports.upsertReview = async (userId, bookId, soSao, nhanXet) => {
    if (soSao < 1 || soSao > 5) {
        throw new Error("Số sao phải từ 1 đến 5");
    }

    if (!nhanXet || nhanXet.trim() === "") {
        throw new Error("Nội dung đánh giá không được để trống");
    }
    return await prisma.danh_gia.upsert({
        where: {
            uq_review: { nguoi_dung_id: userId, sach_id: bookId }
        },
        update: {
            so_sao: soSao,
            nhan_xet: nhanXet,
            updated_at: new Date()
        },
        create: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            so_sao: soSao,
            nhan_xet: nhanXet
        }
    });
};
// Lấy danh sách đánh giá của một cuốn sách
exports.getReviewsByBook = async (bookId) => {
    return await prisma.danh_gia.findMany({
        where: { sach_id: bookId },
        include: { nguoi_dung: { select: { ten_hien_thi: true, anh_dai_dien: true } } },
        orderBy: { created_at: 'desc' }
    });
};

// Xóa đánh giá
exports.deleteReview = async (reviewId, userId) => {
    return await prisma.danh_gia.deleteMany({
        where: { id: reviewId, nguoi_dung_id: userId }
    });
};