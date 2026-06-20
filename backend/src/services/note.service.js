const prisma = require('../config/prisma');

// Thêm ghi chú mới
exports.createNote = async (userId, bookId, soTrang, noiDung) => {
    return await prisma.ghi_chu_doc.create({
        data: { nguoi_dung_id: userId, sach_id: bookId, so_trang: soTrang, noi_dung: noiDung }
    });
};

// Lấy danh sách ghi chú của một cuốn sách
exports.getNotesByBook = async (userId, bookId) => {
    return await prisma.ghi_chu_doc.findMany({
        where: { nguoi_dung_id: userId, sach_id: bookId },
        orderBy: { so_trang: 'asc' }
    });
};

// Cập nhật nội dung ghi chú
exports.updateNote = async (noteId, userId, noiDung) => {
    return await prisma.ghi_chu_doc.updateMany({
        where: { id: noteId, nguoi_dung_id: userId },
        data: { noi_dung: noiDung, updated_at: new Date() }
    });
};

// Xóa ghi chú
exports.deleteNote = async (noteId, userId) => {
    return await prisma.ghi_chu_doc.deleteMany({
        where: { id: noteId, nguoi_dung_id: userId }
    });
};