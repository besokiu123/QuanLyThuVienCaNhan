// middlewares/role.middleware.js
module.exports = (...allowedRoles) => {
    // 🔥 Hỗ trợ cả string và array
    const roles = allowedRoles.flat();

    return (req, res, next) => {
        const userRole = req.user?.vai_tro;

        console.log('🔍 ===== ROLE CHECK =====');
        console.log('🔍 User role:', userRole);
        console.log('🔍 Allowed roles:', roles);

        if (!userRole) {
            return res.status(401).json({
                success: false,
                message: 'Thiếu thông tin phân quyền'
            });
        }

        if (!roles.includes(userRole)) {
            return res.status(403).json({
                success: false,
                message: `Bạn không có quyền truy cập. Cần role: ${roles.join(', ')}`
            });
        }

        console.log('✅ Role check passed!');
        next();
    };
};