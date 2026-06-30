const prisma = require('../config/prisma');

// ================= THÊM/CẬP NHẬT ĐÁNH GIÁ =================
exports.upsertReview = async (userId, bookId, soSao, nhanXet) => {
    try {
        // Validate
        if (soSao < 1 || soSao > 5) {
            throw new Error("Số sao phải từ 1 đến 5");
        }

        if (!nhanXet || nhanXet.trim() === "") {
            throw new Error("Nội dung đánh giá không được để trống");
        }

        // Kiểm tra sách tồn tại
        const book = await prisma.sach.findUnique({
            where: { id: bookId }
        });

        if (!book) {
            throw new Error("Không tìm thấy sách");
        }

        // Upsert review
        const result = await prisma.danh_gia.upsert({
            where: {
                nguoi_dung_id_sach_id: {
                    nguoi_dung_id: userId,
                    sach_id: bookId
                }
            },
            update: {
                so_sao: soSao,
                nhan_xet: nhanXet.trim(),
                updated_at: new Date()
            },
            create: {
                nguoi_dung_id: userId,
                sach_id: bookId,
                so_sao: soSao,
                nhan_xet: nhanXet.trim()
            }
        });

        return result;
    } catch (error) {
        console.error('❌ Upsert review error:', error);
        throw error;
    }
};

// ================= LẤY DANH SÁCH ĐÁNH GIÁ CỦA SÁCH =================
exports.getReviewsByBook = async (bookId) => {
    try {
        return await prisma.danh_gia.findMany({
            where: { sach_id: bookId },
            include: {
                nguoi_dung: {
                    select: {
                        ten_hien_thi: true,
                        anh_dai_dien: true
                    }
                }
            },
            orderBy: { created_at: 'desc' }
        });
    } catch (error) {
        console.error('❌ Get reviews error:', error);
        return [];
    }
};

// ================= XÓA ĐÁNH GIÁ =================
exports.deleteReview = async (reviewId, userId) => {
    try {
        // Kiểm tra review tồn tại và thuộc về user
        const review = await prisma.danh_gia.findFirst({
            where: {
                id: reviewId,
                nguoi_dung_id: userId
            }
        });

        if (!review) {
            throw new Error("Không tìm thấy đánh giá hoặc bạn không có quyền xóa");
        }

        return await prisma.danh_gia.delete({
            where: { id: reviewId }
        });
    } catch (error) {
        console.error('❌ Delete review error:', error);
        throw error;
    }
};