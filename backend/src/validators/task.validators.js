const { z } = require('zod');
const { priorities, statuses } = require('../models/Task');
const { buildStartAt } = require('../utils/taskTime');

const timeSchema = z
  .object({
    hour: z.coerce.number().int().min(0).max(23),
    minute: z.coerce.number().int().min(0).max(59),
    day: z.coerce.number().int().min(1).max(31),
    month: z.coerce.number().int().min(1).max(12),
    year: z.coerce.number().int().min(1970).max(3000)
  })
  .refine((time) => buildStartAt(time) !== null, {
    message: 'Thời gian không phải là ngày hợp lệ.'
  });

const durationMinutes = z.coerce
  .number()
  .int()
  .min(1, 'Thời lượng phải ít nhất 1 phút.')
  .max(10080, 'Thời lượng tối đa là 7 ngày.');

const createTaskSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1).max(160),
    priority: z.enum(priorities).default('normal'),
    description: z.string().trim().max(4000).optional().default(''),
    time: timeSchema,
    durationMinutes: durationMinutes.optional().default(60),
    status: z.enum(statuses).optional().default('new')
  }),
  query: z.object({}).passthrough(),
  params: z.object({}).passthrough()
});

const updateTaskSchema = z.object({
  body: z
    .object({
      name: z.string().trim().min(1).max(160).optional(),
      priority: z.enum(priorities).optional(),
      description: z.string().trim().max(4000).optional(),
      time: timeSchema.optional(),
      durationMinutes: durationMinutes.optional(),
      status: z.enum(statuses).optional()
    })
    .refine((body) => Object.keys(body).length > 0, {
      message: 'Cần ít nhất một trường công việc để cập nhật.'
    }),
  query: z.object({}).passthrough(),
  params: z.object({
    id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Mã công việc không hợp lệ.')
  })
});

const listTasksSchema = z.object({
  body: z.object({}).passthrough(),
  query: z.object({
    status: z.enum(statuses).optional(),
    priority: z.enum(priorities).optional()
  }),
  params: z.object({}).passthrough()
});

const taskIdSchema = z.object({
  body: z.object({}).passthrough(),
  query: z.object({}).passthrough(),
  params: z.object({
    id: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Mã công việc không hợp lệ.')
  })
});

module.exports = {
  createTaskSchema,
  listTasksSchema,
  taskIdSchema,
  updateTaskSchema
};
