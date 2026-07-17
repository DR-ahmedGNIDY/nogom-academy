const mongoose = require('mongoose');
const EntryLog = require('../models/entryLog.model');
const Player = require('../models/player.model');
const Academy = require('../models/academy.model');
const Group = require('../models/group.model');
const AppError = require('../utils/AppError');
const { sendSuccess, sendPaginated } = require('../utils/apiResponse');
const logger = require('../utils/logger');
const { logActivity } = require('../utils/activityLogger');

// ─── أدوات الوقت (الخادم هو المصدر الوحيد للزمن) ────────────────────────────
const pad2 = (n) => String(n).padStart(2, '0');
const serverDateStr = (d = new Date()) =>
  `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
const serverTimeStr = (d = new Date()) => `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;

// تطبيع كود اللاعب القادم من الـ QR: يقبل 'PLAYER:Y-0001' أو 'Y-0001'.
// نستخدم نفس صيغة الـ QR الحالية دون أي تعديل عليها.
const normalizeCode = (raw) => {
  if (!raw) return '';
  return String(raw).trim().replace(/^PLAYER:/i, '').trim();
};

// ─── نطاق الأكاديمية ─────────────────────────────────────────────────────────
/**
 * يُرجع الأكاديمية التي يقتصر عليها الطلب:
 *   • super_admin و security → عامّان عبر كل الأكاديميات، يمرّران academyId
 *     اختيارياً (null = كل الأكاديميات).
 *   • academy_admin → مُقيَّد بأكاديميته حتماً، ولا يستطيع طلب غيرها.
 *   • أي دور آخر (coach / admin) لا يصل إلى هنا أصلاً — محجوب في الـ routes.
 */
const resolveAcademyScope = (req) => {
  if (req.user.role === 'super_admin' || req.user.role === 'security') {
    return req.query.academyId ? String(req.query.academyId) : null;
  }
  return req.user.academyId ? req.user.academyId.toString() : null;
};

/** يبني فلتر الأكاديمية بحيث لا يستطيع academy_admin تجاوز أكاديميته. */
const applyAcademyFilter = (req, filter) => {
  const scope = resolveAcademyScope(req);
  if (scope) filter.academyId = scope;
};

// ─── POST /entry-logs ────────────────────────────────────────────────────────
// تسجيل دخول لاعب. لا علاقة له إطلاقاً بـ Attendance — لا يُنشئ أي سجل حضور تدريب.
const createEntryLog = async (req, res, next) => {
  const { code, playerId, entryMethod, notes, deviceInfo } = req.body;

  // 1) العثور على اللاعب — بالكود من الـ QR أو بالمعرّف (بحث يدوي).
  let player;
  if (playerId) {
    player = await Player.findById(playerId);
  } else {
    const normalized = normalizeCode(code);
    if (!normalized) return next(new AppError('كود اللاعب مطلوب', 400));
    player = await Player.findOne({ playerCode: normalized });
  }

  if (!player || player.isActive === false) {
    return next(new AppError('اللاعب غير موجود', 404));
  }

  // 2) فحص النطاق — academy_admin لا يسجّل دخولاً للاعب من أكاديمية أخرى.
  //    super_admin و security عامّان عبر كل الأكاديميات.
  const isGlobal = req.user.role === 'super_admin' || req.user.role === 'security';
  if (!isGlobal && player.academyId.toString() !== req.user.academyId?.toString()) {
    return next(new AppError('ليس لديك صلاحية لتسجيل دخول هذا اللاعب', 403));
  }

  // 3) بناء اللقطات (snapshots) — الاسم يبقى صحيحاً تاريخياً حتى لو تغيّر لاحقاً.
  const [academy, group] = await Promise.all([
    Academy.findById(player.academyId).select('name'),
    player.groupId ? Group.findById(player.groupId).select('name') : Promise.resolve(null),
  ]);

  // 4) الزمن من الخادم حصراً — لا يُقبل أي وقت من العميل.
  const now = new Date();

  const entryLog = await EntryLog.create({
    academyId: player.academyId,
    academyName: academy ? academy.name : '',
    playerId: player._id,
    playerCode: player.playerCode,
    playerName: player.fullName,
    groupId: player.groupId || null,
    groupName: group ? group.name : null,
    sport: player.sport || null,
    entryDate: serverDateStr(now),
    entryTime: serverTimeStr(now),
    entryTimestamp: now,
    entryMethod: entryMethod === 'MANUAL' ? 'MANUAL' : 'QR',
    securityUserId: req.user._id,
    securityUserName: req.user.name || '',
    deviceInfo: deviceInfo || null,
    notes: notes || null,
  });

  logger.info(
    `EntryLog created: ${player.playerCode} - ${player.fullName} @ ${entryLog.entryDate} ${entryLog.entryTime} by ${req.user.email}`
  );
  logActivity(req, {
    actionType: 'RECORD_ENTRY_LOG',
    entityType: 'ENTRY_LOG',
    entityId: entryLog._id,
    entityName: player.fullName,
    academyId: player.academyId,
  });

  return sendSuccess(res, {
    data: {
      entryLog,
      player: {
        id: player._id.toString(),
        fullName: player.fullName,
        playerCode: player.playerCode,
        sport: player.sport,
        image_url: player.image_url,
        groupName: group ? group.name : null,
        academyName: academy ? academy.name : '',
      },
    },
    message: 'تم تسجيل دخول اللاعب بنجاح',
    statusCode: 201,
  });
};

// ─── GET /entry-logs ─────────────────────────────────────────────────────────
// سجل الدخول مع الفلاتر: التاريخ/نطاق تاريخي، الأكاديمية، المجموعة، اللاعب،
// البحث بالاسم أو الكود، والبحث باسم موظف الأمن.
const getEntryLogs = async (req, res, next) => {
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(200, Math.max(1, parseInt(req.query.limit) || 30));
  const skip = (page - 1) * limit;

  const filter = {};
  applyAcademyFilter(req, filter);

  // يوم محدّد أو نطاق تاريخي (مقارنة نصية صالحة لصيغة YYYY-MM-DD)
  if (req.query.date && /^\d{4}-\d{2}-\d{2}$/.test(req.query.date)) {
    filter.entryDate = req.query.date;
  } else if (req.query.startDate || req.query.endDate) {
    filter.entryDate = {};
    if (req.query.startDate) filter.entryDate.$gte = req.query.startDate;
    if (req.query.endDate) filter.entryDate.$lte = req.query.endDate;
  }

  if (req.query.groupId) filter.groupId = req.query.groupId;
  if (req.query.playerId) filter.playerId = req.query.playerId;
  if (req.query.sport && req.query.sport.trim()) filter.sport = req.query.sport.trim();
  if (req.query.entryMethod && ['QR', 'MANUAL'].includes(req.query.entryMethod)) {
    filter.entryMethod = req.query.entryMethod;
  }

  // البحث عن اللاعب بالاسم أو الكود — يعتمد على اللقطات المخزّنة فلا نحتاج join.
  if (req.query.search && req.query.search.trim().length > 0) {
    const regex = new RegExp(req.query.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    filter.$or = [{ playerName: regex }, { playerCode: regex }];
  }

  // البحث باسم موظف الأمن الذي سجّل الدخول (super_admin أساساً).
  if (req.query.securityUser && req.query.securityUser.trim().length > 0) {
    const regex = new RegExp(
      req.query.securityUser.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i'
    );
    filter.securityUserName = regex;
  }

  const [records, total] = await Promise.all([
    EntryLog.find(filter)
      .populate('playerId', 'fullName playerCode image_url')
      .sort({ entryTimestamp: -1 })
      .skip(skip)
      .limit(limit),
    EntryLog.countDocuments(filter),
  ]);

  return sendPaginated(res, {
    data: records,
    total,
    page,
    limit,
    message: 'تم جلب سجل الدخول بنجاح',
  });
};

// ─── GET /entry-logs/player/:playerId ────────────────────────────────────────
// سجل دخول لاعب واحد — يغذّي تبويب "سجل الدخول" في صفحة اللاعب.
const getPlayerEntryHistory = async (req, res, next) => {
  const { playerId } = req.params;

  const player = await Player.findById(playerId).select('academyId');
  if (!player) return next(new AppError('اللاعب غير موجود', 404));

  // academy_admin يرى لاعبي أكاديميته فقط.
  const isGlobal = req.user.role === 'super_admin' || req.user.role === 'security';
  if (!isGlobal && player.academyId.toString() !== req.user.academyId?.toString()) {
    return next(new AppError('ليس لديك صلاحية للوصول إلى سجل دخول هذا اللاعب', 403));
  }

  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(200, Math.max(1, parseInt(req.query.limit) || 30));
  const skip = (page - 1) * limit;

  const filter = { playerId };
  if (req.query.startDate || req.query.endDate) {
    filter.entryDate = {};
    if (req.query.startDate) filter.entryDate.$gte = req.query.startDate;
    if (req.query.endDate) filter.entryDate.$lte = req.query.endDate;
  }

  const [records, total] = await Promise.all([
    EntryLog.find(filter).sort({ entryTimestamp: -1 }).skip(skip).limit(limit),
    EntryLog.countDocuments(filter),
  ]);

  return sendPaginated(res, {
    data: records,
    total,
    page,
    limit,
    message: 'تم جلب سجل دخول اللاعب بنجاح',
  });
};

// ─── GET /entry-logs/stats ───────────────────────────────────────────────────
// إحصائيات سجل الدخول: اليوم/الأسبوع/الشهر، أكثر المجموعات نشاطاً، أكثر
// أكاديمية نشاطاً، وساعات الذروة.
const getEntryLogStats = async (req, res, next) => {
  const scope = resolveAcademyScope(req);
  const baseMatch = {};
  if (scope) baseMatch.academyId = new mongoose.Types.ObjectId(String(scope));

  const now = new Date();
  const today = serverDateStr(now);

  const weekAgo = new Date(now);
  weekAgo.setDate(weekAgo.getDate() - 6); // آخر 7 أيام شاملة اليوم
  const weekStart = serverDateStr(weekAgo);

  const monthStart = today.slice(0, 8) + '01';

  const [todayCount, weekCount, monthCount, topGroups, topAcademy, peakHours] =
    await Promise.all([
      EntryLog.countDocuments({ ...baseMatch, entryDate: today }),
      EntryLog.countDocuments({ ...baseMatch, entryDate: { $gte: weekStart, $lte: today } }),
      EntryLog.countDocuments({ ...baseMatch, entryDate: { $gte: monthStart, $lte: today } }),

      // أكثر المجموعات نشاطاً خلال الشهر الحالي
      EntryLog.aggregate([
        { $match: { ...baseMatch, entryDate: { $gte: monthStart, $lte: today } } },
        { $match: { groupId: { $ne: null } } },
        {
          $group: {
            _id: '$groupId',
            groupName: { $first: '$groupName' },
            academyName: { $first: '$academyName' },
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 5 },
      ]),

      // أكثر أكاديمية نشاطاً خلال الشهر الحالي
      EntryLog.aggregate([
        { $match: { ...baseMatch, entryDate: { $gte: monthStart, $lte: today } } },
        {
          $group: {
            _id: '$academyId',
            academyName: { $first: '$academyName' },
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 5 },
      ]),

      // ساعات الذروة — تُشتق من نص entryTime ('HH:mm') فلا تتأثر بالمنطقة الزمنية.
      EntryLog.aggregate([
        { $match: { ...baseMatch, entryDate: { $gte: monthStart, $lte: today } } },
        {
          $group: {
            _id: { $substrCP: ['$entryTime', 0, 2] },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

  return sendSuccess(res, {
    data: {
      todayEntries: todayCount,
      weeklyEntries: weekCount,
      monthlyEntries: monthCount,
      mostActiveGroups: topGroups.map((g) => ({
        groupId: g._id ? g._id.toString() : null,
        groupName: g.groupName || '',
        academyName: g.academyName || '',
        count: g.count,
      })),
      mostActiveAcademies: topAcademy.map((a) => ({
        academyId: a._id ? a._id.toString() : null,
        academyName: a.academyName || '',
        count: a.count,
      })),
      peakHours: peakHours.map((h) => ({
        hour: h._id,
        count: h.count,
      })),
      range: { today, weekStart, monthStart },
    },
    message: 'تم جلب إحصائيات سجل الدخول بنجاح',
  });
};

module.exports = {
  createEntryLog,
  getEntryLogs,
  getPlayerEntryHistory,
  getEntryLogStats,
};
