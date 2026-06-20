const prisma = require('../config/prisma');
const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');

const uploadFileToCloudinary = async (fileBuffer) => {
    return new Promise((resolve, reject) => {
        const cldUploadStream = cloudinary.uploader.upload_stream(
            { resource_type: "raw", folder: "book_files" }, // resource_type: "raw" cho PDF/EPUB
            (error, result) => {
                if (error) return reject(error);
                resolve(result.secure_url);
            }
        );
        streamifier.createReadStream(fileBuffer).pipe(cldUploadStream);
    });
};
//them sach
exports.addSach = async (thuThuId, data) => {
    // Nếu thiếu tiêu đề hoặc thể loại, ném lỗi ngay lập tức
    if (!data.tieu_de || !data.the_loai_id) {
        throw new Error("Thiếu thông tin bắt buộc: Tiêu đề hoặc ID thể loại");
    }

    return await prisma.sach.create({
        data: {
            tieu_de: data.tieu_de,
            tac_gia: data.tac_gia,
            nam_xuat_ban: data.nam_xuat_ban,
            tong_so_trang: data.tong_so_trang,
            mo_ta: data.mo_ta,
            anh_bia: data.anh_bia,
            loai_file: data.loai_file,
            file_url: data.file_url,
            the_loai: { connect: { id: data.the_loai_id } },
            nguoi_dung: { connect: { id: thuThuId } }
        }
    });
};
//xoa sach
exports.getSachById = async (id) => {
    return await prisma.sach.findUnique({
        where: { id: id },
        include: {
            the_loai: true,
            nguoi_dung: {
                select: {
                    id: true,
                    ten_hien_thi: true
                }
            }
        }
    });
};
exports.deleteSach = async (id) => {
    return await prisma.sach.delete({ where: { id } });

};
//cap nhat sach
exports.updateSach = async (
    id,
    updateData
) => {
    return prisma.sach.update({
        where: { id },
        data: updateData
    });
};

//lay danh sach sach
exports.getAllSach = async (page, limit) => {
    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 10;
    const skip = (pageNum - 1) * limitNum;

    // Lấy danh sách sách và tổng số lượng để frontend làm phân trang
    const [danhSach, tongSo] = await Promise.all([
        prisma.sach.findMany({
            skip: skip,
            take: limitNum,
            orderBy: { created_at: 'desc' },
            include: { the_loai: true } // Lấy kèm thông tin thể loại
        }),
        prisma.sach.count()
    ]);

    return {
        data: danhSach,
        meta: {
            total: tongSo,
            page: pageNum,
            limit: limitNum,
            totalPages: Math.ceil(tongSo / limitNum)
        }
    };
};
//tìm kiếm và lọc
exports.searchAndFilter = async (query, page = 1, limit = 10) => {
    const { search, theLoai, tacGia, trangThai, userId } = query;
    let filters = {};

    if (search) {
        filters.OR = [
            { tieu_de: { contains: search, mode: 'insensitive' } },
            { tac_gia: { contains: search, mode: 'insensitive' } }
        ];
    }
    if (theLoai) filters.the_loai_id = theLoai;
    if (trangThai && userId) {
        filters.tien_do_doc = { some: { nguoi_dung_id: userId, trang_thai: trangThai } };
    }
    if (tacGia) {
        filters.tac_gia = {
            contains: tacGia,
            mode: 'insensitive'
        };
    }

    return await prisma.sach.findMany({
        where: filters,
        skip: (page - 1) * limit,
        take: limit,
        include: { the_loai: true }
    });
};