const bookmarkService = require('../services/danhDauTrang.service');

exports.add = async (req, res) => {
    try {
        const { bookId, soTrang } = req.body;
        const bookmark = await bookmarkService.createBookmark(req.user.id, bookId, soTrang);
        res.status(201).json(bookmark);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getAllByBook = async (req, res) => {
    try {
        const bookmarks = await bookmarkService.getBookmarksByBook(req.user.id, req.params.bookId);
        res.status(200).json(bookmarks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.remove = async (req, res) => {
    try {
        await bookmarkService.deleteBookmark(req.params.id, req.user.id);
        res.status(200).json({ message: "Đã xóa đánh dấu" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};