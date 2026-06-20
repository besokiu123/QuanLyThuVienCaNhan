# Backend - Thư Viện Cá Nhân

Backend này là REST API cho ứng dụng quản lý thư viện cá nhân. Dự án dùng Node.js, Express, Prisma và PostgreSQL, hỗ trợ đăng ký/đăng nhập, quản lý sách, thể loại, ghi chú, đánh dấu trang, tiến độ đọc, đánh giá, mục tiêu đọc và thống kê cá nhân.

## Công nghệ chính

- Node.js + Express
- PostgreSQL
- Prisma ORM
- JWT cho xác thực
- Multer để nhận file upload
- Cloudinary để lưu ảnh bìa và file sách

## Chạy dự án

1. Cài dependencies trong thư mục `backend`
2. Tạo file `.env`
3. Đồng bộ Prisma schema nếu cần
4. Chạy `npm run dev`

## Biến môi trường

```env
PORT=5000
DATABASE_URL=postgresql://...
JWT_SECRET=your_secret
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

## Cấu trúc thư mục

- `server.js`: điểm khởi động server, kết nối database rồi mở cổng
- `src/app.js`: khai báo Express app và mount toàn bộ routes
- `src/config/`: cấu hình Prisma và Cloudinary
- `src/controllers/`: xử lý request/response
- `src/services/`: chứa logic nghiệp vụ và truy cập dữ liệu qua Prisma
- `src/routes/`: định nghĩa endpoint
- `src/middlewares/`: xác thực, phân quyền, upload file
- `prisma/schema.prisma`: schema dữ liệu và quan hệ

## Các nhóm API

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`

### Books

- `POST /api/books/`
- `DELETE /api/books/:id`
- `PATCH /api/books/:id`
- `GET /api/books/`
- `GET /api/books/:id`
- `GET /api/books/search`

### Reading

- `GET /api/reading/progress/:bookId`
- `POST /api/reading/progress`
- `POST /api/reading/session`

### Notes

- `POST /api/note/`
- `GET /api/note/:bookId`
- `PUT /api/note/:id`
- `DELETE /api/note/:id`

### Bookmarks

- `POST /api/danhDauTrang/add`
- `GET /api/danhDauTrang/book/:bookId`
- `DELETE /api/danhDauTrang/delete/:id`

### Reviews

- `POST /api/review/`
- `GET /api/review/:bookId`
- `DELETE /api/review/:id`

### Goals

- `POST /api/goal/`
- `GET /api/goal/:nam`

### Stats

- `GET /api/stats/my-stats`

### Categories

- `GET /api/theLoai/`
- `GET /api/theLoai/:id`
- `POST /api/theLoai/`
- `PUT /api/theLoai/:id`
- `DELETE /api/theLoai/:id`

## Dữ liệu và quan hệ chính

- `nguoi_dung`: người dùng, vai trò `THU_THU` hoặc `DOC_GIA`
- `sach`: sách, gắn với thể loại và người tạo
- `the_loai`: thể loại sách
- `tien_do_doc`: tiến độ đọc theo từng sách và người dùng
- `ghi_chu_doc`: ghi chú theo từng sách
- `danh_dau_trang`: đánh dấu trang
- `danh_gia`: đánh giá sách
- `muc_tieu_doc`: mục tiêu đọc theo năm
- `phien_doc`: lịch sử/phien đọc

## Lưu ý hiện trạng

- Route sách đã được chuẩn hóa để dùng upload ảnh bìa và file sách qua Cloudinary.
- Middleware JWT hiện yêu cầu `Authorization: Bearer <token>`.
- Nếu triển khai production, nên kiểm tra lại quyền đăng ký tài khoản và không để `JWT_SECRET` mặc định.
