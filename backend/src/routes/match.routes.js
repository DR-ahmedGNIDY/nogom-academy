const express = require('express');
const { body } = require('express-validator');
const {
  getMatches,
  getMatchById,
  createMatch,
  updateMatch,
  deleteMatch,
  addPlayersToMatch,
  removePlayerFromMatch,
  logReminder,
} = require('../controllers/match.controller');
const { protect, restrictTo } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');

const router = express.Router();

router.use(protect);

// إنشاء/تعديل/حذف المباريات وإدارة لاعبيها وتذكيراتها مقصور على
// super_admin و supervisor — مدير الأكاديمية (academy_admin) يرى المباريات
// فقط (GET) دون أي صلاحية تعديل.
const canManageMatches = restrictTo('super_admin', 'supervisor');

const createValidators = [
  body('name')
    .notEmpty().withMessage('اسم المباراة مطلوب')
    .isLength({ min: 2, max: 150 }).withMessage('اسم المباراة يجب أن يكون بين 2 و 150 حرف'),
  body('location')
    .notEmpty().withMessage('مكان المباراة مطلوب')
    .isLength({ max: 200 }).withMessage('مكان المباراة طويل جداً'),
  body('date')
    .notEmpty().withMessage('تاريخ المباراة مطلوب')
    .matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('صيغة التاريخ غير صحيحة'),
  body('time')
    .notEmpty().withMessage('وقت المباراة مطلوب')
    .matches(/^\d{2}:\d{2}$/).withMessage('صيغة الوقت غير صحيحة'),
  body('notes').optional({ checkFalsy: true }).isLength({ max: 500 }),
  body('sport').optional({ checkFalsy: true }).isLength({ max: 60 }),
];

const updateValidators = [
  body('name').optional().isLength({ min: 2, max: 150 }),
  body('location').optional().isLength({ max: 200 }),
  body('date').optional().matches(/^\d{4}-\d{2}-\d{2}$/),
  body('time').optional().matches(/^\d{2}:\d{2}$/),
  body('notes').optional({ checkFalsy: true }).isLength({ max: 500 }),
  body('sport').optional({ checkFalsy: true }).isLength({ max: 60 }),
];

const addPlayersValidators = [
  body('playerIds').isArray({ min: 1 }).withMessage('قائمة اللاعبين مطلوبة'),
];

// GET    /matches
router.get('/', getMatches);

// GET    /matches/:id
router.get('/:id', getMatchById);

// POST   /matches
router.post('/', canManageMatches, createValidators, validate, createMatch);

// PUT    /matches/:id
router.put('/:id', canManageMatches, updateValidators, validate, updateMatch);

// DELETE /matches/:id
router.delete('/:id', canManageMatches, deleteMatch);

// POST   /matches/:id/players
router.post('/:id/players', canManageMatches, addPlayersValidators, validate, addPlayersToMatch);

// DELETE /matches/:id/players/:playerId
router.delete('/:id/players/:playerId', canManageMatches, removePlayerFromMatch);

// POST   /matches/:id/reminders/:playerId
router.post('/:id/reminders/:playerId', canManageMatches, logReminder);

module.exports = router;
