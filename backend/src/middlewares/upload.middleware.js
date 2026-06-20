const multer = require('multer');
const storage = multer.memoryStorage(); // Lưu ảnh tạm vào RAM
const upload = multer({ storage: storage });

module.exports = upload;