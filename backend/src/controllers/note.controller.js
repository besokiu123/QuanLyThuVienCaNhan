const noteService = require('../services/note.service');

exports.add = async (req, res) => {
    try {
        const { bookId, soTrang, noiDung } = req.body;
        const note = await noteService.createNote(req.user.id, bookId, soTrang, noiDung);
        res.status(201).json(note);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getByBook = async (req, res) => {
    try {
        const notes = await noteService.getNotesByBook(req.user.id, req.params.bookId);
        res.status(200).json(notes);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.update = async (req, res) => {
    try {
        const { noiDung } = req.body;
        await noteService.updateNote(req.params.id, req.user.id, noiDung);
        res.status(200).json({ message: "Đã cập nhật ghi chú" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.remove = async (req, res) => {
    try {
        await noteService.deleteNote(req.params.id, req.user.id);
        res.status(200).json({ message: "Đã xóa ghi chú" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};