process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '1h';
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/calendar-for-work-test';

const assert = require('node:assert/strict');
const test = require('node:test');
const mongoose = require('mongoose');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const { Task } = require('../src/models/Task');

let mongoServer;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
});

test.after(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

test.beforeEach(async () => {
  await mongoose.connection.db.dropDatabase();
});

function taskTimeFromDate(date) {
  return {
    hour: date.getUTCHours(),
    minute: date.getUTCMinutes(),
    day: date.getUTCDate(),
    month: date.getUTCMonth() + 1,
    year: date.getUTCFullYear()
  };
}

async function createAuthenticatedUser(email = 'macvinh92@example.com') {
  const user = {
    username: 'macvinh92',
    email,
    password: 'secret123'
  };

  const registerResponse = await request(app)
    .post('/api/auth/register')
    .send(user)
    .expect(201);

  return {
    token: registerResponse.body.token,
    user: registerResponse.body.user,
    password: user.password
  };
}

test('register, login, and manage authenticated tasks', async () => {
  const user = {
    username: 'macvinh92',
    email: 'macvinh92@example.com',
    password: 'secret123'
  };

  const registerResponse = await request(app)
    .post('/api/auth/register')
    .send(user)
    .expect(201);

  assert.equal(registerResponse.body.user.email, user.email);
  assert.ok(registerResponse.body.token);
  assert.equal(registerResponse.body.user.passwordHash, undefined);

  await request(app).post('/api/auth/register').send(user).expect(409);

  const loginResponse = await request(app)
    .post('/api/auth/login')
    .send({ email: user.email, password: user.password })
    .expect(200);

  const token = loginResponse.body.token;

  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const createResponse = await request(app)
    .post('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Hoan thanh backend',
      priority: 'urgent',
      description: 'Tao API cho ung dung CalendarForWork',
      time: taskTimeFromDate(tomorrow),
      durationMinutes: 120
    })
    .expect(201);

  assert.equal(createResponse.body.task.priorityRank, 4);
  assert.equal(createResponse.body.task.status, 'new');
  assert.equal(createResponse.body.task.durationMinutes, 120);

  const taskId = createResponse.body.task._id;

  const updateResponse = await request(app)
    .patch(`/api/tasks/${taskId}`)
    .set('Authorization', `Bearer ${token}`)
    .send({ status: 'in_progress', priority: 'high' })
    .expect(200);

  assert.equal(updateResponse.body.task.status, 'in_progress');
  assert.equal(updateResponse.body.task.priorityRank, 3);

  const listResponse = await request(app)
    .get('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .expect(200);

  assert.equal(listResponse.body.tasks.length, 1);
  assert.equal(listResponse.body.tasks[0]._id, taskId);
});

test('task routes require authentication', async () => {
  await request(app).get('/api/tasks').expect(401);
});

test('task cannot be created or moved into the past', async () => {
  const { token } = await createAuthenticatedUser('past-check@example.com');
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);

  await request(app)
    .post('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Qua khu',
      priority: 'normal',
      description: 'Khong duoc tao',
      time: taskTimeFromDate(yesterday)
    })
    .expect(400);

  const createResponse = await request(app)
    .post('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Tuong lai',
      priority: 'normal',
      time: taskTimeFromDate(tomorrow)
    })
    .expect(201);

  await request(app)
    .patch(`/api/tasks/${createResponse.body.task._id}`)
    .set('Authorization', `Bearer ${token}`)
    .send({ time: taskTimeFromDate(yesterday) })
    .expect(400);
});

test('overdue tasks are automatically completed on fetch', async () => {
  const { token, user } = await createAuthenticatedUser('auto-complete@example.com');
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const overdueTask = await Task.create({
    user: user._id,
    name: 'Qua han',
    priority: 'high',
    description: 'Task qua han se tu dong done',
    time: taskTimeFromDate(yesterday),
    durationMinutes: 60,
    dueAt: yesterday,
    status: 'in_progress'
  });

  const listResponse = await request(app)
    .get('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .expect(200);

  assert.equal(listResponse.body.tasks.length, 1);
  assert.equal(listResponse.body.tasks[0]._id, overdueTask._id.toString());
  assert.equal(listResponse.body.tasks[0].status, 'done');
});

test('task remains active while duration has not ended', async () => {
  const { token, user } = await createAuthenticatedUser('duration-check@example.com');
  const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
  const completionTime = new Date(thirtyMinutesAgo.getTime() + 120 * 60 * 1000);

  const activeTask = await Task.create({
    user: user._id,
    name: 'Dang trong thoi luong',
    priority: 'normal',
    description: 'Task da bat dau nhung chua het thoi luong',
    time: taskTimeFromDate(thirtyMinutesAgo),
    durationMinutes: 120,
    dueAt: completionTime,
    status: 'in_progress'
  });

  const listResponse = await request(app)
    .get('/api/tasks')
    .set('Authorization', `Bearer ${token}`)
    .expect(200);

  assert.equal(listResponse.body.tasks.length, 1);
  assert.equal(listResponse.body.tasks[0]._id, activeTask._id.toString());
  assert.equal(listResponse.body.tasks[0].status, 'in_progress');
});
