const goalService = require('../services/goal.service');

exports.set = async (req, res) => {
    try {
        const { nam, soLuong } = req.body;
        const goal = await goalService.setGoal(req.user.id, nam, soLuong);
        res.status(200).json(goal);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getProgress = async (req, res) => {
    try {
        const nam = parseInt(req.params.nam) || new Date().getFullYear();
        const progress = await goalService.getMyProgress(req.user.id, nam);
        res.status(200).json(progress);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};