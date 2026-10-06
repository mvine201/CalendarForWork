const { Task, priorityWeights } = require('../models/Task');
const HttpError = require('../utils/httpError');
const { buildDueAt, buildStartAt } = require('../utils/taskTime');
const {
  assertStartAtIsFuture,
  completeOverdueTasks
} = require('../services/taskLifecycle.service');

async function createTask(req, res, next) {
  try {
    const taskInput = req.validated.body;
    const startAt = buildStartAt(taskInput.time);
    const dueAt = buildDueAt(taskInput.time, taskInput.durationMinutes);
    assertStartAtIsFuture(startAt);

    const task = await Task.create({
      ...taskInput,
      dueAt,
      user: req.user._id
    });

    res.status(201).json({ task });
  } catch (error) {
    next(error);
  }
}

async function listTasks(req, res, next) {
  try {
    await completeOverdueTasks(Task, req.user._id);

    const filter = { user: req.user._id };
    const { status, priority } = req.validated.query;

    if (status) filter.status = status;
    if (priority) filter.priority = priority;

    const tasks = await Task.find(filter).sort({
      status: 1,
      priorityRank: -1,
      dueAt: 1,
      createdAt: -1
    });

    res.json({ tasks });
  } catch (error) {
    next(error);
  }
}

async function getTask(req, res, next) {
  try {
    await completeOverdueTasks(Task, req.user._id);

    const task = await Task.findOne({
      _id: req.validated.params.id,
      user: req.user._id
    });

    if (!task) {
      throw new HttpError(404, 'Không tìm thấy công việc.');
    }

    res.json({ task });
  } catch (error) {
    next(error);
  }
}

async function updateTask(req, res, next) {
  try {
    const existingTask = await Task.findOne({
      _id: req.validated.params.id,
      user: req.user._id
    });

    if (!existingTask) {
      throw new HttpError(404, 'Không tìm thấy công việc.');
    }

    const update = { ...req.validated.body };

    if (update.time || update.durationMinutes) {
      const nextTime = update.time || existingTask.time;
      const nextDuration = update.durationMinutes || existingTask.durationMinutes || 60;
      const nextStartAt = buildStartAt(nextTime);
      update.dueAt = buildDueAt(nextTime, nextDuration);
      assertStartAtIsFuture(nextStartAt);
    }

    if (update.priority) {
      update.priorityRank = priorityWeights[update.priority];
    }

    const task = await Task.findOneAndUpdate(
      { _id: existingTask._id },
      update,
      {
        new: true,
        runValidators: true
      }
    );

    res.json({ task });
  } catch (error) {
    next(error);
  }
}

async function deleteTask(req, res, next) {
  try {
    const task = await Task.findOneAndDelete({
      _id: req.validated.params.id,
      user: req.user._id
    });

    if (!task) {
      throw new HttpError(404, 'Không tìm thấy công việc.');
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createTask,
  deleteTask,
  getTask,
  listTasks,
  updateTask
};
