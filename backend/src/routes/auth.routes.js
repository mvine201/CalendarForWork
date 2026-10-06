const express = require('express');
const authenticate = require('../middleware/auth');
const validate = require('../middleware/validate');
const { login, me, register } = require('../controllers/auth.controller');
const { loginSchema, registerSchema } = require('../validators/auth.validators');

const router = express.Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);
router.get('/me', authenticate, me);

module.exports = router;
