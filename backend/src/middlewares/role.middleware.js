module.exports = (...allowedRoles) => {
    return (req, res, next) => {
        const userRole = req.user?.vai_tro;

        if (!userRole) {
            return res.status(401).json({ message: 'thieu thong tin phan quyen' });
        }

        if (!allowedRoles.includes(userRole)) {
            return res.status(403).json({ message: 'ban khong co quyen truy cap' });
        }

        next();
    };
};