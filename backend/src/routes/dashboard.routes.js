const express = require('express');
const router = express.Router();

const { protect, restrictTo } = require('../middleware/auth.middleware');
const {
  getDashboardStats,
  getRevenueByMonth,
  getSubscriptionsByType,
  getPlayersByBirthYear,
  getEvaluationDistribution,
  getRecentActivities,
  getSportStats,
} = require('../controllers/dashboard.controller');

router.use(protect);
router.use(restrictTo('super_admin', 'supervisor', 'academy_admin', 'coach'));

// coach محجوب عن الإيرادات — لا يملك صلاحية التقارير المالية. بقية المسارات
// مسموحة له، وكلها محصورة تلقائياً بأكاديميته عبر buildAcademyMatch.
const noFinance = restrictTo('super_admin', 'supervisor', 'academy_admin');

router.get('/stats', getDashboardStats);
router.get('/revenue-by-month', noFinance, getRevenueByMonth);
router.get('/subscriptions-by-type', getSubscriptionsByType);
router.get('/players-by-birth-year', getPlayersByBirthYear);
router.get('/evaluation-distribution', getEvaluationDistribution);
router.get('/recent-activities', getRecentActivities);
router.get('/sport-stats', getSportStats);

module.exports = router;
