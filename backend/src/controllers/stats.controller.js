const statsService = require('../services/stats.service');

exports.getStats = async (req, res) => {
    try {
        const stats = await statsService.getUserStats(req.user.id);
        res.status(200).json(stats);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};