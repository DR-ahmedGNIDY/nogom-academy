const mongoose = require('mongoose');
const logger = require('../utils/logger');

// Masks credentials in a MongoDB URI, leaving only the host visible —
// e.g. "mongodb+srv://user:pass@cluster.x.mongodb.net/db" -> "cluster.x.mongodb.net".
const maskedHost = () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) return 'unknown';
  const match = uri.match(/@([^/?]+)/);
  return match ? match[1] : 'unparseable';
};

// Tracks when the current connection attempt started, so we can log how
// long it took (or warn if it's taking unusually long) without ever
// printing the connection string itself.
let connectStartedAt = null;
const SLOW_CONNECTION_WARNING_MS = 10000;
let slowConnectionTimer = null;

mongoose.connection.on('connected', () => {
  const durationMs = connectStartedAt ? Date.now() - connectStartedAt : null;
  if (slowConnectionTimer) {
    clearTimeout(slowConnectionTimer);
    slowConnectionTimer = null;
  }
  logger.info(
    `✅ MongoDB Connected | host=${maskedHost()} | readyState=${mongoose.connection.readyState} | durationMs=${durationMs ?? 'n/a'}`
  );
});

mongoose.connection.on('disconnected', () => {
  logger.warn(`⚠️ MongoDB Disconnected | host=${maskedHost()} | readyState=${mongoose.connection.readyState}`);
});

mongoose.connection.on('reconnected', () => {
  logger.info(`🔄 MongoDB Reconnected | host=${maskedHost()} | readyState=${mongoose.connection.readyState}`);
});

mongoose.connection.on('error', (err) => {
  logger.error(`❌ MongoDB Error | host=${maskedHost()} | readyState=${mongoose.connection.readyState} | ${err.message}`);
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

  connectStartedAt = Date.now();
  logger.info(`MongoDB ReadyState before connect: ${mongoose.connection.readyState} | host=${maskedHost()}`);

  // Warn (without failing the request) if the connection attempt is taking
  // longer than expected — surfaces slow Atlas/network conditions in logs
  // before the driver's own buffering timeout kicks in.
  slowConnectionTimer = setTimeout(() => {
    logger.warn(
      `⏱️ MongoDB connection attempt exceeded ${SLOW_CONNECTION_WARNING_MS}ms | host=${maskedHost()} | readyState=${mongoose.connection.readyState}`
    );
  }, SLOW_CONNECTION_WARNING_MS);

  connectionPromise = mongoose
    .connect(process.env.MONGODB_URI, { dbName: 'basketball_academy' })
    .then((conn) => conn)
    .catch((error) => {
      if (slowConnectionTimer) {
        clearTimeout(slowConnectionTimer);
        slowConnectionTimer = null;
      }
      logger.error(`❌ MongoDB connect failed | host=${maskedHost()} | ${error.message}`);
      connectionPromise = null; // allow retrying on the next request
      throw error;
    });

  return connectionPromise;
};

// Used by the /api/v1/db-health endpoint — never exposes the URI or any
// credentials, only connection state.
const getDbHealth = () => {
  const states = ['disconnected', 'connected', 'connecting', 'disconnecting'];
  const readyState = mongoose.connection.readyState;
  return {
    status: states[readyState] || 'unknown',
    readyState,
    host: readyState === 1 ? mongoose.connection.host : maskedHost(),
    uptimeSeconds: readyState === 1 && connectStartedAt
      ? Math.floor((Date.now() - connectStartedAt) / 1000)
      : null,
  };
};

module.exports = connectDB;
module.exports.getDbHealth = getDbHealth;
