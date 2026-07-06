const express = require('express');
const { body } = require('express-validator');
const {
  getGroups,
  getGroupsByAcademy,
  getGroupsBySport,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
} = require('../controllers/group.controller');
const { protect, restrictTo } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');

const router = express.Router();

router.use(protect);

// إنشاء وحذف المجموعات مقصور على super_admin. تعديل المجموعات متاح أيضاً
// لـ academy_admin (يرى ويعدّل وينقل اللاعبين)، بينما supervisor يمكنه فقط
// تعيين/تغيير مجموعة اللاعب عبر PATCH /players/:id/change-group.
const canCreateOrDelete = restrictTo('super_admin');
const canEdit = restrictTo('super_admin', 'academy_admin');

const createValidators = [
  body('name')
    .notEmpty().withMessage('اسم المجموعة مطلوب')
    .isLength({ min: 2, max: 150 }).withMessage('اسم المجموعة يجب أن يكون بين 2 و 150 حرف'),
  body('ageGroup').optional({ checkFalsy: true }).isLength({ max: 60 }),
  body('capacity').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('السعة يجب أن تكون رقم صحيح 1 أو أكثر'),
  body('sportId').optional({ checkFalsy: true }).isLength({ max: 60 }),
  body('coachId').optional({ checkFalsy: true }).isMongoId().withMessage('معرّف المدرب غير صحيح'),
];

const updateValidators = [
  body('name').optional().isLength({ min: 2, max: 150 }),
  body('ageGroup').optional({ checkFalsy: true }).isLength({ max: 60 }),
  body('capacity').optional({ checkFalsy: true }).isInt({ min: 1 }),
  body('sportId').optional({ checkFalsy: true }).isLength({ max: 60 }),
  body('coachId').optional({ checkFalsy: true }).isMongoId(),
  body('isActive').optional().isBoolean(),
];

// GET    /groups
router.get('/', getGroups);

// GET    /groups/academy/:academyId
router.get('/academy/:academyId', getGroupsByAcademy);

// GET    /groups/sport/:sportId
router.get('/sport/:sportId', getGroupsBySport);

// GET    /groups/:id
router.get('/:id', getGroupById);

// POST   /groups
router.post('/', canCreateOrDelete, createValidators, validate, createGroup);

// PATCH  /groups/:id
router.patch('/:id', canEdit, updateValidators, validate, updateGroup);

// DELETE /groups/:id
router.delete('/:id', canCreateOrDelete, deleteGroup);

module.exports = router;
