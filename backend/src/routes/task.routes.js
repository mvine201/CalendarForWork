const express = require('express');
const authenticate = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  createTask,
  deleteTask,
  getTask,
  listTasks,
  updateTask
} = require('../controllers/task.controller');
const {
  createTaskSchema,
  listTasksSchema,
  taskIdSchema,
  updateTaskSchema
} = require('../validators/task.validators');

const router = express.Router();

router.use(authenticate);

router.post('/', validate(createTaskSchema), createTask);
router.get('/', validate(listTasksSchema), listTasks);
router.get('/:id', validate(taskIdSchema), getTask);
router.patch('/:id', validate(updateTaskSchema), updateTask);
router.delete('/:id', validate(taskIdSchema), deleteTask);

module.exports = router;
