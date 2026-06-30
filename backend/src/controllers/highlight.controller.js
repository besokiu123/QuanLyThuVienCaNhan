const highlightService = require('../services/highlight.service');

exports.getByBook = async (req, res) => {
  try {
    const highlights = await highlightService.getByBook(
      req.user.id,
      req.params.bookId
    );
    res.status(200).json({ success: true, data: highlights });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.create = async (req, res) => {
  try {
    const { bookId, cfi, text, color, note } = req.body;
    const highlight = await highlightService.create(
      req.user.id,
      bookId,
      { cfi, text, color, note }
    );
    res.status(201).json({ success: true, data: highlight });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    await highlightService.delete(req.params.id, req.user.id);
    res.status(200).json({ success: true, message: 'Đã xóa highlight' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
exports.update = async (req, res) => {
  try {
    const highlight = await highlightService.update(
      req.params.id,
      req.user.id,
      req.body
    );

    res.json({
      success: true,
      data: highlight,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};