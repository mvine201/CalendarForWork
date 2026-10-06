const { z } = require('zod');

const username = z
  .string()
  .trim()
  .min(3, 'Tên người dùng phải có ít nhất 3 ký tự.')
  .max(32, 'Tên người dùng tối đa 32 ký tự.');

const password = z
  .string()
  .min(6, 'Mật khẩu phải có ít nhất 6 ký tự.')
  .max(128, 'Mật khẩu quá dài.');

const email = z.string().trim().email('Email không hợp lệ.').toLowerCase();

const registerSchema = z.object({
  body: z.object({
    username,
    password,
    email
  }),
  query: z.object({}).passthrough(),
  params: z.object({}).passthrough()
});

const loginSchema = z.object({
  body: z.object({
    email,
    password
  }),
  query: z.object({}).passthrough(),
  params: z.object({}).passthrough()
});

module.exports = {
  loginSchema,
  registerSchema
};
