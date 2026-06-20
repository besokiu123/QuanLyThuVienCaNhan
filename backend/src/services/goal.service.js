const prisma = require('../config/prisma');

//tao hoac cap nhat muc tieu
exports.setGoal = async (userId, nam, soLuongSach) => {
    return await prisma.muc_tieu_doc.upsert({
        where: {
            nguoi_dung_id_nam: { nguoi_dung_id: userId, nam: nam }
        },
        update: { so_sach_muc_tieu: soLuongSach },
        create: { nguoi_dung_id: userId, nam: nam, so_sach_muc_tieu: soLuongSach }
    });
};
//lay tien do hien tai so voi muc tieu
exports.getMyProgress = async (userId, nam) => {
    // 1. Lấy mục tiêu của năm
    const goal = await prisma.muc_tieu_doc.findUnique({
        where: {
            nguoi_dung_id_nam: { nguoi_dung_id: userId, nam: nam }
        }
    });

    // 2. Đếm số sách đã hoàn thành trong năm đó
    const startDate = new Date(`${nam}-01-01T00:00:00Z`);
    const endDate = new Date(`${Number(nam) + 1}-01-01T00:00:00Z`);

    const completedBooks = await prisma.tien_do_doc.count({
        where: {
            nguoi_dung_id: userId,
            trang_thai: 'DA_HOAN_THANH',
            ngay_hoan_thanh: {
                gte: startDate,
                lt: endDate
            }
        }
    });

    // 3. Tính toán và trả về kết quả
    const mucTieu = goal ? goal.so_sach_muc_tieu : 0;

    return {
        nam: nam,
        mucTieu: mucTieu,
        daHoanThanh: completedBooks,
        phanTram: mucTieu > 0 ? Math.round((completedBooks / mucTieu) * 100) : 0,
        conLai: mucTieu > completedBooks ? (mucTieu - completedBooks) : 0
    };
};