const statsService = require('../services/stats.service');

// ====== USER STATS ======
exports.getUserStats = async (req, res) => {
    try {
        const stats = await statsService.getUserStats(req.user.id);
        res.status(200).json(stats);
    } catch (error) {
        console.error('❌ Get user stats error:', error);
        res.status(500).json({ message: error.message });
    }
};

// ====== ADMIN STATS ======
exports.getAdminDashboard = async (req, res) => {
    try {
        if (req.user.vai_tro !== 'THU_THU') {
            return res.status(403).json({ message: "Không có quyền truy cập!" });
        }
        const stats = await statsService.getAdminStats();
        res.status(200).json({ data: stats });
    } catch (error) {
        console.error('❌ Get admin stats error:', error);
        res.status(500).json({ message: error.message });
    }
};