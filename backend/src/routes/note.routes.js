const express = require('express');
const router = express.Router();
const noteController = require('../controllers/note.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.post('/', authMiddleware, noteController.add);
router.get('/:bookId', authMiddleware, noteController.getByBook);
router.put('/:id', authMiddleware, noteController.update);
router.delete('/:id', authMiddleware, noteController.remove);

module.exports = router;