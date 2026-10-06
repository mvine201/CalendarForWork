const assert = require('node:assert/strict');
const test = require('node:test');
const { buildDueAt, buildStartAt } = require('../src/utils/taskTime');

test('buildStartAt creates a valid UTC date from task time parts', () => {
  const startAt = buildStartAt({
    hour: 9,
    minute: 30,
    day: 6,
    month: 10,
    year: 2026
  });

  assert.equal(startAt.toISOString(), '2026-10-06T09:30:00.000Z');
});

test('buildDueAt adds task duration to the start time', () => {
  const dueAt = buildDueAt(
    {
      hour: 9,
      minute: 30,
      day: 6,
      month: 10,
      year: 2026
    },
    120
  );

  assert.equal(dueAt.toISOString(), '2026-10-06T11:30:00.000Z');
});

test('buildDueAt rejects impossible calendar dates', () => {
  const dueAt = buildDueAt({
    hour: 9,
    minute: 30,
    day: 31,
    month: 2,
    year: 2026
  });

  assert.equal(dueAt, null);
});
