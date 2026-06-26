const express = require('express');
const router = express.Router();
const statsController = require('../controllers/stats.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const roleMiddleware = require('../middlewares/role.middleware');

// ====== USER STATS ======
// Lấy thống kê cá nhân của user
router.get('/', authMiddleware, statsController.getUserStats);  

// ====== ADMIN STATS ======
router.get(
    '/admin-dashboard',
    authMiddleware,
    roleMiddleware('THU_THU'),
    statsController.getAdminDashboard
);

module.exports = router;