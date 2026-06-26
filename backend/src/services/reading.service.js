const prisma = require('../config/prisma');

// ================= UPDATE PROGRESS =================
exports.updateTienDo = async (userId, bookId, trangHienTai, epubCfi) => {
    // Lấy thông tin sách
    const sach = await prisma.sach.findUnique({
        where: { id: bookId },
        select: { tong_so_trang: true, loai_file: true }
    });

    if (!sach) {
        throw new Error('Không tìm thấy sách');
    }

    const isEpub = sach.loai_file?.toUpperCase() === 'EPUB';
    
    // 🔥 XỬ LÝ TRANG HIỆN TẠI
    let safePage = trangHienTai ?? 0;
    if (!isEpub && safePage <= 0) safePage = 1;
    
    // 🔥 XỬ LÝ CFI (chỉ cho EPUB)
    let finalEpubCfi = null;
    if (isEpub && epubCfi !== undefined && epubCfi !== null && epubCfi.trim() !== '') {
        // Làm sạch CFI: loại bỏ [pg-footer] và [pg-header]
        finalEpubCfi = epubCfi.trim()
            .replace(/\[pg-footer\]/g, '')
            .replace(/\[pg-header\]/g, '');
        console.log('✅ Saving CFI (cleaned):', finalEpubCfi);
    } else if (isEpub) {
        // Nếu là EPUB và không có CFI mới, giữ CFI cũ
        const current = await prisma.tien_do_doc.findUnique({
            where: {
                nguoi_dung_id_sach_id: {
                    nguoi_dung_id: userId,
                    sach_id: bookId
                }
            },
            select: { epub_cfi: true }
        });
        if (current?.epub_cfi) {
            finalEpubCfi = current.epub_cfi
                .replace(/\[pg-footer\]/g, '')
                .replace(/\[pg-header\]/g, '');
        }
    }

    // 🔥 TÍNH PHẦN TRĂM
    let phanTram = 0;
    if (isEpub) {
        // EPUB: lấy phần trăm cũ nếu có
        const current = await prisma.tien_do_doc.findUnique({
            where: {
                nguoi_dung_id_sach_id: {
                    nguoi_dung_id: userId,
                    sach_id: bookId
                }
            },
            select: { phan_tram_tien_do: true }
        });
        phanTram = current?.phan_tram_tien_do ?? 0;
        
        // Nếu có số trang, tính % từ số trang
        if (safePage > 0 && sach.tong_so_trang > 0) {
            phanTram = Math.min(Math.round((safePage / sach.tong_so_trang) * 100), 100);
        }
    } else {
        // PDF: tính % từ số trang
        if (sach.tong_so_trang > 0) {
            phanTram = Math.min(Math.round((safePage / sach.tong_so_trang) * 100), 100);
        }
    }

    // 🔥 KIỂM TRA HOÀN THÀNH (chỉ cho PDF)
    const isCompleted = !isEpub && sach.tong_so_trang > 0 && safePage >= sach.tong_so_trang;

    // Lấy progress hiện tại
    const currentProgress = await prisma.tien_do_doc.findUnique({
        where: {
            nguoi_dung_id_sach_id: {
                nguoi_dung_id: userId,
                sach_id: bookId
            }
        }
    });

    // Xử lý ngày hoàn thành
    const ngayHoanThanh = isCompleted && !currentProgress?.ngay_hoan_thanh
        ? new Date()
        : currentProgress?.ngay_hoan_thanh ?? null;

    // 🔥 XÁC ĐỊNH TRẠNG THÁI
    let trangThai = 'DANG_DOC';
    if (isEpub) {
        // EPUB: nếu có CFI hoặc trang > 0 thì là đang đọc
        trangThai = (finalEpubCfi || safePage > 0) ? 'DANG_DOC' : 'CHUA_DOC';
    } else {
        trangThai = isCompleted ? 'DA_HOAN_THANH' : 'DANG_DOC';
    }

    console.log('📝 Saving:', { safePage, finalEpubCfi, phanTram, trangThai });

    // Upsert
    const result = await prisma.tien_do_doc.upsert({
        where: {
            nguoi_dung_id_sach_id: {
                nguoi_dung_id: userId,
                sach_id: bookId
            }
        },
        update: {
            trang_hien_tai: safePage,
            epub_cfi: finalEpubCfi,
            phan_tram_tien_do: phanTram,
            trang_thai: trangThai,
            updated_at: new Date(),
            ngay_hoan_thanh: ngayHoanThanh
        },
        create: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            trang_hien_tai: safePage,
            epub_cfi: finalEpubCfi,
            phan_tram_tien_do: phanTram,
            trang_thai: trangThai,
            ngay_bat_dau: new Date(),
            ngay_hoan_thanh: isCompleted ? new Date() : null
        }
    });

    return result;
};

// ================= GET PROGRESS =================
exports.getTienDo = async (userId, bookId) => {
    const progress = await prisma.tien_do_doc.findUnique({
        where: {
            nguoi_dung_id_sach_id: {
                nguoi_dung_id: userId,
                sach_id: bookId
            }
        },
        select: {
            trang_hien_tai: true,
            epub_cfi: true,
            phan_tram_tien_do: true,
            trang_thai: true,
            ngay_bat_dau: true,
            ngay_hoan_thanh: true,
            updated_at: true
        }
    });

    // 🔥 LÀM SẠCH CFI TRƯỚC KHI TRẢ VỀ
    if (progress?.epub_cfi) {
        progress.epub_cfi = progress.epub_cfi
            .replace(/\[pg-footer\]/g, '')
            .replace(/\[pg-header\]/g, '');
    }

    return progress;
};

// ================= ADD SESSION =================
exports.taoPhienDoc = async (userId, bookId, data) => {
    if (!data.trangBatDau || !data.trangKetThuc || !data.phut) {
        throw new Error('Thiếu dữ liệu phiên đọc');
    }

    let startPage = data.trangBatDau;
    let endPage = data.trangKetThuc;
    if (startPage > endPage) {
        [startPage, endPage] = [endPage, startPage];
    }

    return await prisma.phien_doc.create({
        data: {
            nguoi_dung_id: userId,
            sach_id: bookId,
            trang_bat_dau: startPage,
            trang_ket_thuc: endPage,
            thoi_gian_doc_phut: Math.min(data.phut, 999),
            ngay_doc: new Date()
        }
    });
};