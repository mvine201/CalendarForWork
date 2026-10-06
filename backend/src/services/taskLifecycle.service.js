const HttpError = require('../utils/httpError');

function assertStartAtIsFuture(startAt) {
  if (!(startAt instanceof Date) || Number.isNaN(startAt.getTime())) {
    throw new HttpError(400, 'Thời gian công việc không hợp lệ.');
  }

  if (startAt.getTime() <= Date.now()) {
    throw new HttpError(400, 'Không thể lên lịch công việc trong quá khứ.');
  }
}

async function completeOverdueTasks(Task, userId) {
  await Task.updateMany(
    {
      user: userId,
      status: { $ne: 'done' },
      dueAt: { $lte: new Date() }
    },
    {
      $set: { status: 'done' }
    }
  );
}

module.exports = {
  assertStartAtIsFuture,
  completeOverdueTasks
};
