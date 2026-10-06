const app = require('./app');
const connectDatabase = require('./config/database');
const env = require('./config/env');

async function start() {
  try {
    await connectDatabase();
    app.listen(env.port, () => {
      console.log(`CalendarForWork API is running on port ${env.port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
}

start();
