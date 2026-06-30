const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors());
app.use(express.json()); 

app.use("/api/auth", require("./routes/auth.routes"));
app.use("/api/books", require("./routes/book.routes"));
app.use('/api/reading', require('./routes/reading.routes'));
app.use('/api/note', require('./routes/note.routes'));
app.use('/api/theLoai', require('./routes/theLoai.routes'));
app.use('/api/danhDauTrang', require('./routes/danhDauTrang.routes')); 
app.use('/api/review', require('./routes/review.routes'));
app.use('/api/goal', require('./routes/goal.routes'));
app.use('/api/stats', require('./routes/stats.routes'));
// Thêm route user
app.use('/api/highlights', require('./routes/highlight.routes'));
app.use("/api/users", require("./routes/user.routes"));
module.exports = app;