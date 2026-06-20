const prisma = require('../config/prisma');

// Cập nhật hoặc tạo tiến độ đọc (Dùng cho trang hiện tại)

exports.updateTienDo = async (userId, bookId, trangHienTai) => {
    const sach = await prisma.sach.findUnique({ where: { id: bookId } });
    const phanTram = sach ? Math.round((trangHienTai / sach.tong_so_trang) * 100) : 0;

    // Logic xác định đã hoàn thành chưa
    const isCompleted = sach && trangHienTai >= sach.tong_so_trang;
    const currentProgress = await prisma.tien_do_doc.findUnique({
        where: {
            nguoi_dung_id_sach_id: {
                nguoi_dung_id: userId,
                sach_id: bookId
            }
        }
    });
    const ngayHoanThanh =
        isCompleted && !currentProgress?.ngay_hoan_thanh
            ? new Date()
            : currentProgress?.ngay_hoan_thanh;
    return await prisma.tien_do_doc.upsert({
        where: {
            nguoi_dung_id_sach_id: { nguoi_dung_id: userId, sach_id: bookId }
        },

        update: {
            trang_hien_tai: trangHienTai,
            phan_tram_tien_do: phanTram,
            trang_thai: isCompleted ? 'DA_HOAN_THANH' : 'DANG_DOC',
            updated_at: new Date(),
            ngay_hoan_thanh: ngayHoanThanh
        },
        create: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            trang_hien_tai: trangHienTai,
            phan_tram_tien_do: phanTram,
            trang_thai: isCompleted ? 'DA_HOAN_THANH' : 'DANG_DOC',
            ngay_bat_dau: new Date(),
            ngay_hoan_thanh: isCompleted ? new Date() : null
        }
    });
};
// Lấy tiến độ hiện tại

exports.getTienDo = async (userId, bookId) => {
    return await prisma.tien_do_doc.findUnique({
        where: {
            nguoi_dung_id_sach_id: {
                nguoi_dung_id: userId,
                sach_id: bookId
            }
        }
    });
};

// Ghi lại một phiên đọc (Thống kê thời gian)
exports.taoPhienDoc = async (userId, bookId, data) => {
    return await prisma.phien_doc.create({
        data: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            trang_bat_dau: data.trangBatDau,
            trang_ket_thuc: data.trangKetThuc,
            thoi_gian_doc_phut: data.phut,
            ngay_doc: new Date()
        }
    });
};