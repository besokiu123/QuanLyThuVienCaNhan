const prisma = require('../config/prisma');

// Thống kê tổng quan cho User (Dashboard cá nhân)
exports.getUserStats = async (userId) => {
    // 1. Tổng số sách đang đọc và đã xong
    const progress = await prisma.tien_do_doc.groupBy({
        by: ['trang_thai'],
        where: { nguoi_dung_id: userId },
        _count: { trang_thai: true }
    });

    // 2. Tổng thời gian đọc (phút)
    const totalTime = await prisma.phien_doc.aggregate({
        where: { nguoi_dung_id: userId },
        _sum: { thoi_gian_doc_phut: true }
    });

    // 3. Top thể loại hay đọc nhất (Dựa trên số sách đã thêm vào tiến độ)
    const topGenres = await prisma.tien_do_doc.findMany({
        where: { nguoi_dung_id: userId },
        include: { sach: { include: { the_loai: true } } }
    });

    return {
        progress,
        totalMinutes: totalTime._sum.thoi_gian_doc_phut || 0,
        booksRead: progress.find(p => p.trang_thai === 'DA_HOAN_THANH')?._count.trang_thai || 0
    };
};