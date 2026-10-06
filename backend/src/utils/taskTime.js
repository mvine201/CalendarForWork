const MIN_YEAR = 1970;
const MAX_YEAR = 3000;

function buildStartAt(time) {
  if (!time) return null;

  const { hour, minute, day, month, year } = time;
  const date = new Date(Date.UTC(year, month - 1, day, hour, minute, 0, 0));

  const isValid =
    Number.isInteger(hour) &&
    Number.isInteger(minute) &&
    Number.isInteger(day) &&
    Number.isInteger(month) &&
    Number.isInteger(year) &&
    year >= MIN_YEAR &&
    year <= MAX_YEAR &&
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day &&
    date.getUTCHours() === hour &&
    date.getUTCMinutes() === minute;

  return isValid ? date : null;
}

function buildDueAt(time, durationMinutes = 60) {
  const startAt = buildStartAt(time);
  if (!startAt) return null;
  return new Date(startAt.getTime() + durationMinutes * 60 * 1000);
}

module.exports = {
  buildStartAt,
  buildDueAt
};
