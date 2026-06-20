const express = require('express');
const router = express.Router();
const goalController = require('../controllers/goal.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.post('/', authMiddleware, goalController.set);
router.get('/:nam', authMiddleware, goalController.getProgress);

module.exports = router;