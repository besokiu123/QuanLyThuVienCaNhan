const prisma = require('../config/prisma');

// Lấy danh sách thể loại
exports.getAllTheLoai = async () => {
	return await prisma.the_loai.findMany({
		orderBy: {
			ten_the_loai: 'asc'
		}
	});
};

// Lấy chi tiết thể loại
exports.getTheLoaiById = async (id) => {
	return await prisma.the_loai.findUnique({
		where: { id }
	});
};

// Tạo thể loại
exports.createTheLoai = async (data) => {

	const existed = await prisma.the_loai.findFirst({
		where: {
			ten_the_loai: data.ten_the_loai
		}
	});

	if (existed) {
		throw new Error('Tên thể loại đã tồn tại');
	}

	return await prisma.the_loai.create({
		data: {
			ten_the_loai: data.ten_the_loai,
			mo_ta: data.mo_ta ?? null
		}
	});
};

// Cập nhật thể loại
exports.updateTheLoai = async (id, data) => {
	return await prisma.the_loai.update({
		where: { id },
		data
	});
};

// Xóa thể loại
exports.deleteTheLoai = async (id) => {

	const soSach = await prisma.sach.count({
		where: {
			the_loai_id: id
		}
	});

	if (soSach > 0) {
		throw new Error('Thể loại đang chứa sách');
	}

	return await prisma.the_loai.delete({
		where: { id }
	});
};