const mongoose = require('mongoose');
const logger = require('../utils/logger');

mongoose.connection.on('error', (err) => {
  logger.error(`MongoDB خطأ: ${err.message}`);
});
mongoose.connection.on('disconnected', () => {
  logger.warn('MongoDB انقطع الاتصال');
});

// In a serverless environment the process is reused across invocations, so
// avoid reconnecting (and avoid crashing the whole function instance) on
// every call. process.exit() here would kill in-flight requests being
// served by the same warm instance — including unrelated ones like CORS
// preflight — so connection failures are only ever logged, never fatal.
let connectionPromise = null;

const connectDB = async () => {
  if (mongoose.connection.readyState === 1) return mongoose.connection;
  if (connectionPromise) return connectionPromise;

  connectionPromise = mongoose
    .connect(process.env.MONGODB_URI, { dbName: 'basketball_academy' })
    .then((conn) => {
      logger.info(`✅ MongoDB متصل: ${conn.connection.host}`);
      return conn;
    })
    .catch((error) => {
      logger.error(`❌ فشل الاتصال بـ MongoDB: ${error.message}`);
      connectionPromise = null; // allow retrying on the next request
      throw error;
    });

  return connectionPromise;
};

module.exports = connectDB;
