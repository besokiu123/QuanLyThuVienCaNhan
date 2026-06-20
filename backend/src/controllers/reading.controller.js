const readingService = require('../services/reading.service');

exports.saveProgress = async (req, res) => {
    try {
        const { bookId, trangHienTai } = req.body;
        await readingService.updateTienDo(req.user.id, bookId, trangHienTai);
        res.status(200).json({ message: "Đã lưu vị trí đọc" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getProgress = async (req, res) => {
    try {
        const { bookId } = req.params;
        const progress = await readingService.getTienDo(req.user.id, bookId);
        res.status(200).json(progress || { trang_hien_tai: 1 });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.addReadingSession = async (req, res) => {
    try {
        const { bookId, trangBatDau, trangKetThuc, phut } = req.body;
        await readingService.taoPhienDoc(req.user.id, bookId, { trangBatDau, trangKetThuc, phut });
        res.status(201).json({ message: "Lịch sử đọc đã được lưu" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};