const express = require('express');
const router = express.Router();

const theLoaiController = require('../controllers/theLoai.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const roleMiddleware = require('../middlewares/role.middleware');

router.get('/', authMiddleware, theLoaiController.getAll);

router.get('/:id', authMiddleware, theLoaiController.getById);

router.post(
    '/',
    authMiddleware,
    roleMiddleware('THU_THU'),
    theLoaiController.create
);

router.put(
    '/:id',
    authMiddleware,
    roleMiddleware('THU_THU'),
    theLoaiController.update
);

router.delete(
    '/:id',
    authMiddleware,
    roleMiddleware('THU_THU'),
    theLoaiController.deleteTheLoai
);

module.exports = router;