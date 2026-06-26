const sachService = require('../services/book.service');
const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');
const path = require('path');

const uploadImageToCloudinary = async (fileBuffer) => {
    return new Promise((resolve, reject) => {
        const stream =
            cloudinary.uploader.upload_stream(
                {
                    folder: "book_covers"
                },
                (error, result) => {
                    if (error) return reject(error);
                    resolve({
                        url: result.secure_url,
                        public_id: result.public_id,
                        format: result.format
                    });
                }
            );

        streamifier
            .createReadStream(fileBuffer)
            .pipe(stream);
    });
};
// 1. ĐỊNH NGHĨA HÀM UPLOAD FILE SÁCH (RAW)
const uploadFileToCloudinary = async (fileBuffer,originalName) => {
    return new Promise((resolve, reject) => {
        const cldUploadStream = cloudinary.uploader.upload_stream(
            {
                resource_type: "raw",
                folder: "book_files",
                use_filename: true,
                unique_filename: true,
                filename_override: originalName
            },
            (error, result) => {
                if (error) return reject(error);

                resolve({
                    url: result.secure_url,
                    public_id: result.public_id,
                    format: result.format
                });
            }
        );

        streamifier
            .createReadStream(fileBuffer)
            .pipe(cldUploadStream);
    });
};

exports.addSach = async (req, res) => {
    try {
        // 2. Kiểm tra ảnh bìa
        const anhBiaFile = req.files?.anh_bia ? req.files.anh_bia[0] : null;
        if (!anhBiaFile) return res.status(400).json({ message: "Vui lòng chọn ảnh bìa" });

        // 3. Upload ảnh bìa lên Cloudinary
        const uploadedImage = await new Promise((resolve, reject) => {
            const cldUploadStream = cloudinary.uploader.upload_stream(
                { folder: "book_covers" },
                (error, result) => {
                    if (error) return reject(error);
                    resolve(result);
                }
            );
            streamifier.createReadStream(anhBiaFile.buffer).pipe(cldUploadStream);
        });

        // 4. Xử lý file sách (PDF/EPUB)
        const uploadedFile = req.files?.file_sach ? req.files.file_sach[0] : null;
        let fileUrl = req.body.file_url;
        let loai = req.body.loai_file || 'PDF';
        if (!uploadedFile && !fileUrl) {
            return res.status(400).json({
                message: "Vui lòng upload PDF/EPUB hoặc nhập URL sách"
            });
        }
        if (uploadedFile) {
            const ext = path.extname(uploadedFile.originalname).toLowerCase();

            if (ext === '.epub') loai = 'EPUB';
            else if (ext === '.pdf') loai = 'PDF';

            const uploadedResult =
                await uploadFileToCloudinary(
                    uploadedFile.buffer,
                    uploadedFile.originalname
                );

            fileUrl = uploadedResult.url;
        }

        // 5. Chuẩn hóa dữ liệu
        const bookData = {
            tieu_de: req.body.tieu_de,
            tac_gia: req.body.tac_gia || "Chưa cập nhật",
            nam_xuat_ban: req.body.nam_xuat_ban ? parseInt(req.body.nam_xuat_ban) : null,
            tong_so_trang: parseInt(req.body.tong_so_trang) || 1,
            mo_ta: req.body.mo_ta || "",
            the_loai_id: req.body.the_loai_id,
            loai_file: loai,
            file_url: fileUrl,
            anh_bia: uploadedImage.secure_url
        };

        // 6. Gọi Service
        const newSach = await sachService.addSach(req.user.id, bookData);

        res.status(201).json({ message: 'Thêm sách thành công!', data: newSach });
    } catch (error) {
        console.error("Lỗi thêm sách:", error);
        res.status(500).json({ message: error.message });
    }
};
exports.deleteSach = async (req, res) => {
    try {
        const { id } = req.params;
        const sach = await sachService.getSachById(id);
        if (!sach) {
            return res.status(404).json({ message: "Không tìm thấy sách" });
        }
        const getPublicId = (url) => {
            return url.split('/').pop().split('.')[0];
        }
        if (sach.anh_bia) {
            await cloudinary.uploader.destroy(
                `book_covers/${getPublicId(sach.anh_bia)}`
            );
        }
        if (sach.file_url && sach.file_url.includes('cloudinary.com')) {
            await cloudinary.uploader.destroy(`book_files/${getPublicId(sach.file_url)}`, { resource_type: 'raw' });
        }
        await sachService.deleteSach(id);
        res.status(200).json({ message: "Xóa sách thành công" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}
//cap nhat sach
exports.updateSach = async (req, res) => {
    try {
        const { id } = req.params;
        const sachCu = await sachService.getSachById(id);
        if (!sachCu) {
            return res.status(404).json({ message: "khong tim thay sach" });
        }
        let anh_bia = sachCu.anh_bia;
        let file_url = sachCu.file_url;
        if (req.files?.anh_bia) {
            const uploadedImage =
                await uploadImageToCloudinary(
                    req.files.anh_bia[0].buffer
                );

            anh_bia = uploadedImage.url;
        }
        if (req.files?.file_sach) {
            const uploadedFile =
                await uploadFileToCloudinary(
                    req.files.file_sach[0].buffer
                );

            file_url = uploadedFile.url;
        }
        const updateData = {
            tieu_de: req.body.tieu_de || sachCu.tieu_de,
            tac_gia: req.body.tac_gia || sachCu.tac_gia,
            nam_xuat_ban: req.body.nam_xuat_ban ? parseInt(req.body.nam_xuat_ban) : sachCu.nam_xuat_ban,
            tong_so_trang: req.body.tong_so_trang ? parseInt(req.body.tong_so_trang) : sachCu.tong_so_trang,
            mo_ta: req.body.mo_ta || sachCu.mo_ta,
            anh_bia: anh_bia || sachCu.anh_bia,
            loai_file: req.body.loai_file || sachCu.loai_file,
            file_url: file_url || sachCu.file_url,
            the_loai_id: req.body.the_loai_id || sachCu.the_loai_id
        };
        const updatedSach = await sachService.updateSach(id, updateData);
        res.status(200).json({ message: "cap nhat sach thanh cong", data: updatedSach });
    } catch (error) {
        console.error("Lỗi cập nhật sách:", error);
        res.status(500).json({ message: error.message });
    }
};
//lay danh sach sach
exports.getDanhSachSach = async (req, res) => {
    try {
        const { page, limit } = req.query;
        const result = await sachService.getAllSach(page, limit);

        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

//lay chi tiet sach
exports.getChiTietSach = async (req, res) => {
    try {
        const { id } = req.params;
        const sach = await sachService.getSachById(id);

        if (!sach) {
            return res.status(404).json({ message: "Không tìm thấy cuốn sách này" });
        }

        res.status(200).json(sach);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// tim kiem va loc sach
exports.getAll = async (req, res) => {
    try {
        const { page, limit, ...query } = req.query;
        const books = await sachService.searchAndFilter({ ...query, userId: req.user?.id }, page, limit);
        res.status(200).json(books);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
// Thêm vào cuối file
// ================= LẤY SÁCH ĐANG ĐỌC =================
exports.getReadingBooks = async (req, res) => {
    try {
        const books = await sachService.getReadingBooks(req.user.id);
        res.status(200).json({ data: books });
    } catch (error) {
        console.error('❌ Get reading books error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ================= LẤY SÁCH ĐÃ ĐỌC =================
exports.getCompletedBooks = async (req, res) => {
    try {
        const books = await sachService.getCompletedBooks(req.user.id);
        res.status(200).json({ data: books });
    } catch (error) {
        console.error('❌ Get completed books error:', error);
        res.status(500).json({ message: error.message });
    }
};