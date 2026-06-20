const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

console.log("Nội dung authController:", authController); 

router.post('/register', authController.register);
router.post('/login', authController.login);
module.exports=router;