const readingService = require('../services/reading.service');

// ================= SAVE PROGRESS =================
exports.saveProgress = async (req, res) => {
    try {
        const { bookId, trangHienTai, epubCfi } = req.body;

        if (!bookId) {
            return res.status(400).json({
                success: false,
                message: "Thiếu bookId"
            });
        }

        const result = await readingService.updateTienDo(
            req.user.id,
            bookId,
            trangHienTai,
            epubCfi
        );

        // 🔥 Trả về đúng dữ liệu đã lưu
        res.status(200).json({
            success: true,
            message: "Đã lưu vị trí đọc",
            data: {
                trang_hien_tai: result.trang_hien_tai,
                epubCfi: result.epub_cfi, // Trả về CFI đã lưu
                phan_tram: result.phan_tram_tien_do
            }
        });
    } catch (error) {
        console.error('❌ Save progress error:', error);
        res.status(500).json({
            success: false,
            message: "Không thể lưu tiến độ đọc: " + error.message
        });
    }
};

// ================= GET PROGRESS =================
exports.getProgress = async (req, res) => {
    try {
        const { bookId } = req.params;

        if (!bookId) {
            return res.status(400).json({
                success: false,
                message: "Thiếu bookId"
            });
        }

        const progress = await readingService.getTienDo(req.user.id, bookId);

        const response = {
            trang_hien_tai: progress?.trang_hien_tai ?? 1,
            epubCfi: progress?.epub_cfi ?? null, // 🔥 Trả về CFI đã lưu
            phan_tram_tien_do: progress?.phan_tram_tien_do ?? 0,
            trang_thai: progress?.trang_thai ?? 'CHUA_DOC',
            ngay_bat_dau: progress?.ngay_bat_dau ?? null,
            ngay_hoan_thanh: progress?.ngay_hoan_thanh ?? null,
            updated_at: progress?.updated_at ?? null
        };

        res.status(200).json(response);
    } catch (error) {
        console.error('❌ Get progress error:', error);
        res.status(500).json({
            success: false,
            message: "Không thể lấy tiến độ đọc: " + error.message
        });
    }
};

// ================= ADD READING SESSION =================
exports.addReadingSession = async (req, res) => {
    try {
        const { bookId, trangBatDau, trangKetThuc, phut } = req.body;

        if (!bookId || !trangBatDau || !trangKetThuc || !phut) {
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin phiên đọc"
            });
        }

        const result = await readingService.taoPhienDoc(
            req.user.id,
            bookId,
            { trangBatDau, trangKetThuc, phut }
        );

        res.status(201).json({
            success: true,
            message: "Đã lưu phiên đọc",
            data: result
        });
    } catch (error) {
        console.error('❌ Save session error:', error);
        res.status(500).json({
            success: false,
            message: "Không thể lưu phiên đọc: " + error.message
        });
    }
};