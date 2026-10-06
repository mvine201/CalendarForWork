const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/User');
const HttpError = require('../utils/httpError');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const [scheme, token] = authHeader.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throw new HttpError(401, 'Cần token đăng nhập.');
    }

    const payload = jwt.verify(token, env.jwtSecret);
    const user = await User.findById(payload.sub);

    if (!user) {
      throw new HttpError(401, 'Tài khoản người dùng không còn tồn tại.');
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return next(new HttpError(401, 'Token đăng nhập không hợp lệ hoặc đã hết hạn.'));
    }

    return next(error);
  }
}

module.exports = authenticate;
