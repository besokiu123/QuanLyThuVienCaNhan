const prisma = require('../config/prisma');

// ====== USER STATS ======
exports.getUserStats = async (userId) => {
    try {
        console.log('📊 Getting stats for user:', userId);

        // 1. Thống kê trạng thái đọc
        const progress = await prisma.tien_do_doc.groupBy({
            by: ['trang_thai'],
            where: { nguoi_dung_id: userId },
            _count: { trang_thai: true }
        });

        const totalReading = progress.find(p => p.trang_thai === 'DANG_DOC')?._count.trang_thai ?? 0;
        const totalCompleted = progress.find(p => p.trang_thai === 'DA_HOAN_THANH')?._count.trang_thai ?? 0;

        // 2. Tổng thời gian đọc (phút)
        const totalTime = await prisma.phien_doc.aggregate({
            where: { nguoi_dung_id: userId },
            _sum: { thoi_gian_doc_phut: true }
        });
        
        const totalMinutes = totalTime._sum.thoi_gian_doc_phut ?? 0;
        console.log('⏱️ Total minutes:', totalMinutes);

        // 3. Tổng số trang đã đọc
        const totalPages = await prisma.tien_do_doc.aggregate({
            where: { nguoi_dung_id: userId },
            _sum: { trang_hien_tai: true }
        });
        
        const totalPagesRead = totalPages._sum.trang_hien_tai ?? 0;
        console.log('📄 Total pages:', totalPagesRead);

        // 4. Lịch sử đọc gần đây
        const readingHistory = await prisma.phien_doc.findMany({
            where: { nguoi_dung_id: userId },
            orderBy: { ngay_doc: 'desc' },
            take: 10,
            include: {
                sach: {
                    select: {
                        tieu_de: true,
                        tac_gia: true
                    }
                }
            }
        });
        console.log('📚 Reading history:', readingHistory.length);

        // 5. Thống kê thể loại yêu thích
        const allProgress = await prisma.tien_do_doc.findMany({
            where: { nguoi_dung_id: userId },
            include: {
                sach: {
                    include: {
                        the_loai: true
                    }
                }
            }
        });

        const genreMap = {};
        for (const item of allProgress) {
            const genreName = item.sach?.the_loai?.ten_the_loai || 'Khác';
            genreMap[genreName] = (genreMap[genreName] || 0) + 1;
        }

        const sortedGenres = Object.entries(genreMap)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 5);

        const finalGenreMap = {};
        for (const [key, value] of sortedGenres) {
            finalGenreMap[key] = value;
        }

        return {
            totalReading,
            totalCompleted,
            totalMinutes: totalMinutes,
            totalPages: totalPagesRead,
            readingHistory: readingHistory.map(item => ({
                title: item.sach?.tieu_de || 'Không tên',
                pages: item.trang_ket_thuc - item.trang_bat_dau,
                minutes: item.thoi_gian_doc_phut,
                date: item.ngay_doc?.toISOString().split('T')[0] || '',
            })),
            genreStats: finalGenreMap,
        };
    } catch (error) {
        console.error('❌ Get user stats error:', error);
        throw error;
    }
};

// ====== ADMIN STATS ======
exports.getAdminStats = async () => {
    try {
        const totalBooks = await prisma.sach.count();
        const totalUsers = await prisma.nguoi_dung.count();

        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const newArrivals = await prisma.sach.count({
            where: { created_at: { gte: sevenDaysAgo } }
        });

        const totalReading = await prisma.tien_do_doc.count({
            where: { trang_thai: 'DANG_DOC' }
        });

        return {
            totalBooks,
            totalUsers,
            newArrivals,
            totalReading,
        };
    } catch (error) {
        console.error('❌ Get admin stats error:', error);
        throw error;
    }
};