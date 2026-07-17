const express = require('express');
const { body, param, query } = require('express-validator');
const {
  createEntryLog,
  getEntryLogs,
  getPlayerEntryHistory,
  getEntryLogStats,
} = require('../controllers/entryLog.controller');
const { protect, restrictTo } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');

const router = express.Router();

// كل المسارات تتطلّب تسجيل دخول.
router.use(protect);

// ─── RBAC ────────────────────────────────────────────────────────────────────
// سجل الدخول مقصور على: super_admin و academy_admin و security فقط.
// coach و admin (صلاحية محدودة) محجوبان تماماً عن الوحدة — لا يصلان لأي مسار.
router.use(restrictTo('super_admin', 'academy_admin', 'security'));

// إنشاء سجل دخول: الأمن هو من يسجّل عند البوابة، و super_admin كمالك للنظام.
// academy_admin للعرض فقط (متطلّب: "Academy Admin can only view").
const canCreate = restrictTo('super_admin', 'security');

// ملاحظة: لا توجد مسارات PUT/PATCH/DELETE إطلاقاً — التعديل والحذف وتغيير
// الطوابع الزمنية غير ممكنة بنيوياً لأي دور، وليست مجرّد محجوبة بصلاحية.

// ─── Validators ──────────────────────────────────────────────────────────────

const createValidators = [
  body('code')
    .optional({ checkFalsy: true })
    .isLength({ max: 60 }).withMessage('كود اللاعب غير صحيح'),
  body('playerId')
    .optional({ checkFalsy: true })
    .isMongoId().withMessage('معرّف اللاعب غير صحيح'),
  body('entryMethod')
    .optional({ checkFalsy: true })
    .isIn(['QR', 'MANUAL']).withMessage('طريقة الدخول يجب أن تكون QR أو MANUAL'),
  body('notes')
    .optional({ nullable: true })
    .isLength({ max: 500 }).withMessage('الملاحظات لا يمكن أن تتجاوز 500 حرف'),
  body('deviceInfo')
    .optional({ nullable: true })
    .isLength({ max: 200 }).withMessage('معلومات الجهاز لا يمكن أن تتجاوز 200 حرف'),
  // يجب توفّر أحد المُعرّفين على الأقل.
  body().custom((_, { req }) => {
    if (!req.body.code && !req.body.playerId) {
      throw new Error('كود اللاعب أو معرّف اللاعب مطلوب');
    }
    return true;
  }),
];

const listValidators = [
  query('academyId').optional({ checkFalsy: true }).isMongoId().withMessage('معرّف الأكاديمية غير صحيح'),
  query('groupId').optional({ checkFalsy: true }).isMongoId().withMessage('معرّف المجموعة غير صحيح'),
  query('playerId').optional({ checkFalsy: true }).isMongoId().withMessage('معرّف اللاعب غير صحيح'),
  query('date').optional({ checkFalsy: true }).matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('صيغة التاريخ غير صحيحة'),
  query('startDate').optional({ checkFalsy: true }).matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('صيغة تاريخ البداية غير صحيحة'),
  query('endDate').optional({ checkFalsy: true }).matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('صيغة تاريخ النهاية غير صحيحة'),
  query('entryMethod').optional({ checkFalsy: true }).isIn(['QR', 'MANUAL']).withMessage('طريقة الدخول غير صحيحة'),
];

// ─── Routes ──────────────────────────────────────────────────────────────────

// GET /entry-logs/stats  ← يجب أن يسبق أي مسار '/:id' محتمل
router.get('/stats', getEntryLogStats);

// GET /entry-logs/player/:playerId
router.get(
  '/player/:playerId',
  param('playerId').isMongoId().withMessage('معرّف اللاعب غير صحيح'),
  validate,
  getPlayerEntryHistory
);

// GET /entry-logs
router.get('/', listValidators, validate, getEntryLogs);

// POST /entry-logs
router.post('/', canCreate, createValidators, validate, createEntryLog);

module.exports = router;
