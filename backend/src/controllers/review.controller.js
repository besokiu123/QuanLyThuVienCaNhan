const reviewService = require('../services/review.service');

exports.saveReview = async (req, res) => {
    try {
        const { bookId, soSao, nhanXet } = req.body;
        const review = await reviewService.upsertReview(req.user.id, bookId, soSao, nhanXet);
        res.status(200).json(review);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getByBook = async (req, res) => {
    try {
        const reviews = await reviewService.getReviewsByBook(req.params.bookId);
        res.status(200).json(reviews);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.remove = async (req, res) => {
    try {
        await reviewService.deleteReview(req.params.id, req.user.id);
        res.status(200).json({ message: "Đã xóa đánh giá" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};