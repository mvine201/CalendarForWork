const jwt = require('jsonwebtoken');
const User = require('../models/User');
const env = require('../config/env');
const HttpError = require('../utils/httpError');

function signToken(user) {
  return jwt.sign({ sub: user._id.toString(), email: user.email }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn
  });
}

async function register(req, res, next) {
  try {
    const { username, password, email } = req.validated.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new HttpError(409, 'Email này đã có tài khoản.');
    }

    const user = await User.create({
      username,
      email,
      passwordHash: password
    });

    res.status(201).json({
      user,
      token: signToken(user)
    });
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.validated.body;
    const user = await User.findOne({ email }).select('+passwordHash');

    if (!user || !(await user.comparePassword(password))) {
      throw new HttpError(401, 'Email hoặc mật khẩu không đúng.');
    }

    res.json({
      user,
      token: signToken(user)
    });
  } catch (error) {
    next(error);
  }
}

async function me(req, res) {
  res.json({ user: req.user });
}

module.exports = {
  login,
  me,
  register
};
