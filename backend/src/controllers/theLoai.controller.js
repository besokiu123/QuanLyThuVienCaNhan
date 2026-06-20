const prisma = require('../config/prisma');
const theLoaiService = require('../services/theLoai.service');

exports.getAll = async (req, res) => {
    try {
        const list = await theLoaiService.getAllTheLoai();
        res.status(200).json({ message: 'lay danh sach the loai thanh cong', data: list });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getById = async (req, res) => {
    try {
        const { id } = req.params;
        const theLoai = await theLoaiService.getTheLoaiById(id);

        if (!theLoai) {
            return res.status(404).json({ message: 'the loai khong ton tai' });
        }

        res.status(200).json({ message: 'lay chi tiet the loai thanh cong', data: theLoai });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.create = async (req, res) => {
    try {
        const ten_the_loai = req.body?.ten_the_loai ?? req.body?.tenTheLoai;
        const mo_ta = req.body?.mo_ta ?? req.body?.moTa;

        if (!ten_the_loai || !String(ten_the_loai).trim()) {
            return res.status(400).json({ message: 'vui long nhap ten the loai' });
        }
        const existed =
            await prisma.the_loai.findUnique({
                where: {
                    ten_the_loai: String(ten_the_loai).trim()
                }
            });

        if (existed) {
            throw new Error(
                'Tên thể loại đã tồn tại'
            );
        }
        const newTheLoai = await theLoaiService.createTheLoai({
            ten_the_loai: String(ten_the_loai).trim(),
            mo_ta
        });

        res.status(201).json({ message: 'them the loai thanh cong', data: newTheLoai });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.update = async (req, res) => {
    try {
        const { id } = req.params;

        const exist =
            await theLoaiService.getTheLoaiById(id);

        if (!exist) {
            return res.status(404).json({
                message: 'the loai khong ton tai'
            });
        }

        const result =
            await theLoaiService.updateTheLoai(
                id,
                {
                    ...(req.body.ten_the_loai && {
                        ten_the_loai:
                            req.body.ten_the_loai.trim()
                    }),
                    ...(req.body.mo_ta !== undefined && {
                        mo_ta: req.body.mo_ta
                    })
                }
            );

        res.status(200).json({
            message: 'cap nhat the loai thanh cong',
            data: result
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

exports.deleteTheLoai = async (req, res) => {
    try {
        const { id } = req.params;

        const soSach = await prisma.sach.count({
            where: {
                the_loai_id: id
            }
        });

        if (soSach > 0) {
            return res.status(400).json({
                message: 'Thể loại đang chứa sách'
            });
        }

        await theLoaiService.deleteTheLoai(id);

        res.status(200).json({
            message: 'xoa the loai thanh cong'
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};