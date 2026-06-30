const prisma = require('../config/prisma');

// ================= LẤY HIGHLIGHT THEO SÁCH =================
exports.getByBook = async (userId, bookId) => {
    return await prisma.highlight.findMany({
        where: {
            nguoi_dung_id: userId,
            sach_id: bookId
        },
        orderBy: {
            created_at: 'desc'
        }
    });
};

// ================= TẠO HIGHLIGHT MỚI =================
exports.create = async (userId, bookId, data) => {
    // Kiểm tra highlight đã tồn tại chưa
    const existing = await prisma.highlight.findFirst({
        where: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            cfi: data.cfi
        }
    });

    if (existing) {
        // Nếu tồn tại, cập nhật thay vì tạo mới
        return await prisma.highlight.update({
            where: { id: existing.id },
            data: {
                text: data.text,
                color: data.color || existing.color,
                note: data.note || existing.note,
                updated_at: new Date()
            }
        });
    }

    return await prisma.highlight.create({
        data: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            cfi: data.cfi,
            text: data.text,
            color: data.color || '#FFD700',
            note: data.note || null
        }
    });
};

// ================= XÓA HIGHLIGHT =================
exports.delete = async (highlightId, userId) => {
    return await prisma.highlight.deleteMany({
        where: {
            id: highlightId,
            nguoi_dung_id: userId
        }
    });
};