const logger = require('../utils/logger');
const { sendError } = require('../utils/apiResponse');

const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'حدث خطأ غير متوقع';

  if (err.name === 'ValidationError') {
    statusCode = 422;
    message = Object.values(err.errors).map((e) => e.message).join(', ');
  }

  if (err.code === 11000) {
    statusCode = 409;
    const field = Object.keys(err.keyValue)[0];
    message = `القيمة في حقل "${field}" موجودة مسبقاً`;
  }

  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'رمز التحقق غير صحيح';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'انتهت صلاحية رمز التحقق';
  }

  if (err.name === 'CastError') {
    statusCode = 400;
    message = 'معرّف البيانات غير صحيح';
  }

  if (err.code === 'LIMIT_FILE_SIZE') {
    statusCode = 400;
    message = 'حجم الملف أكبر من المسموح به';
  }

  if (statusCode >= 500) {
    logger.error(`${statusCode} - ${message} - ${req.originalUrl}`, { stack: err.stack });
  }

  // تشخيصي فقط — تفاصيل كاملة لكل طلب فاشل (URL/method/duration/exception
  // type/status/body) لتتبّع سبب انقطاعات "انتهت مهلة اتصالك" المتقطعة.
  const durationMs = req._startAtMs ? Date.now() - req._startAtMs : null;
  logger.error(
    `[REQUEST_FAILURE] method=${req.method} url=${req.originalUrl} ` +
      `statusCode=${statusCode} durationMs=${durationMs ?? 'unknown'} ` +
      `exceptionType=${err.name || err.constructor?.name || 'Error'} ` +
      `dbReadyState=${require('mongoose').connection.readyState} ` +
      `responseBody=${message}`
  );

  return sendError(res, { message, statusCode });
};

module.exports = errorHandler;
