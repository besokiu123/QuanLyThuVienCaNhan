const express = require('express');
const router = express.Router();
const statsController = require('../controllers/stats.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.get('/stats', authMiddleware, statsController.getStats);

module.exports = router;