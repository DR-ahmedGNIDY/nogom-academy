const Group = require('../models/group.model');
const Player = require('../models/player.model');
const Academy = require('../models/academy.model');
const AppError = require('../utils/AppError');
const { sendSuccess, sendPaginated } = require('../utils/apiResponse');
const logger = require('../utils/logger');
const { logActivity } = require('../utils/activityLogger');

const resolveAcademyFilter = (req, filter) => {
  if (req.user.role === 'super_admin') {
    if (!req.query.academyId && !req.body.academyId) {
      throw new AppError('معرّف الأكاديمية مطلوب', 400);
    }
    filter.academyId = req.query.academyId || req.body.academyId;
  } else {
    filter.academyId = req.user.academyId;
  }
};

const assertAccess = (req, group, message) => {
  if (req.user.role !== 'super_admin' &&
      group.academyId.toString() !== req.user.academyId?.toString()) {
    throw new AppError(message, 403);
  }
};

const withOccupancy = async (groups) => {
  const groupIds = groups.map((g) => g._id);
  const counts = await Player.aggregate([
    { $match: { groupId: { $in: groupIds }, isActive: true } },
    { $group: { _id: '$groupId', count: { $sum: 1 } } },
  ]);
  const countMap = new Map(counts.map((c) => [c._id.toString(), c.count]));
  return groups.map((g) => {
    const json = g.toJSON();
    const playersCount = countMap.get(g._id.toString()) || 0;
    json.playersCount = playersCount;
    json.occupationRate = json.capacity ? Math.round((playersCount / json.capacity) * 100) : null;
    return json;
  });
};

// ─── GET /groups ─────────────────────────────────────────────────────────────
const getGroups = async (req, res, next) => {
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
  const skip = (page - 1) * limit;

  const filter = {};
  try {
    resolveAcademyFilter(req, filter);
  } catch (err) {
    return next(err);
  }

  if (req.query.sportId && req.query.sportId.trim().length > 0) {
    filter.sportId = req.query.sportId.trim();
  }

  const [groups, total] = await Promise.all([
    Group.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Group.countDocuments(filter),
  ]);

  const data = await withOccupancy(groups);

  return sendPaginated(res, {
    data,
    total,
    page,
    limit,
    message: 'تم جلب المجموعات بنجاح',
  });
};

// ─── GET /groups/academy/:academyId ──────────────────────────────────────────
const getGroupsByAcademy = async (req, res, next) => {
  const { academyId } = req.params;

  if (req.user.role !== 'super_admin' &&
      academyId !== req.user.academyId?.toString()) {
    return next(new AppError('ليس لديك صلاحية للوصول إلى مجموعات هذه الأكاديمية', 403));
  }

  const filter = { academyId };
  if (req.query.sportId && req.query.sportId.trim().length > 0) {
    filter.sportId = req.query.sportId.trim();
  }

  const groups = await Group.find(filter).sort({ name: 1 });
  const data = await withOccupancy(groups);

  return sendSuccess(res, { data, message: 'تم جلب مجموعات الأكاديمية بنجاح' });
};

// ─── GET /groups/sport/:sportId ──────────────────────────────────────────────
const getGroupsBySport = async (req, res, next) => {
  const filter = {};
  try {
    resolveAcademyFilter(req, filter);
  } catch (err) {
    return next(err);
  }
  filter.sportId = req.params.sportId;

  const groups = await Group.find(filter).sort({ name: 1 });
  const data = await withOccupancy(groups);

  return sendSuccess(res, { data, message: 'تم جلب مجموعات الرياضة بنجاح' });
};

// ─── GET /groups/:id ─────────────────────────────────────────────────────────
const getGroupById = async (req, res, next) => {
  const group = await Group.findById(req.params.id);
  if (!group) return next(new AppError('المجموعة غير موجودة', 404));

  try {
    assertAccess(req, group, 'ليس لديك صلاحية للوصول إلى هذه المجموعة');
  } catch (err) {
    return next(err);
  }

  const players = await Player.find({ groupId: group._id, isActive: true });
  const [data] = await withOccupancy([group]);

  return sendSuccess(res, { data: { ...data, players }, message: 'تم جلب بيانات المجموعة بنجاح' });
};

// ─── POST /groups ────────────────────────────────────────────────────────────
const createGroup = async (req, res, next) => {
  let academyId;
  if (req.user.role === 'super_admin') {
    academyId = req.body.academyId;
    if (!academyId) return next(new AppError('معرّف الأكاديمية مطلوب', 400));
  } else {
    academyId = req.user.academyId;
  }

  const { name, ageGroup, capacity, coachId, sportId } = req.body;

  const academy = await Academy.findById(academyId).select('sports');
  if (!academy) return next(new AppError('الأكاديمية غير موجودة', 404));
  const academySports = Array.isArray(academy.sports) && academy.sports.length > 0
    ? academy.sports
    : ['كرة سلة'];

  const groupData = { academyId, name };
  if (academySports.length > 1) {
    const chosen = sportId ? String(sportId).trim() : '';
    if (!chosen) return next(new AppError('الرياضة مطلوبة', 422));
    if (!academySports.includes(chosen)) {
      return next(new AppError('الرياضة المختارة غير متاحة في هذه الأكاديمية', 422));
    }
    groupData.sportId = chosen;
  } else {
    groupData.sportId = academySports[0];
  }

  if (ageGroup !== undefined) groupData.ageGroup = ageGroup;
  if (capacity !== undefined) groupData.capacity = capacity;
  if (coachId !== undefined) groupData.coachId = coachId || null;

  const group = await Group.create(groupData);

  logger.info(`Group created: ${group.name}`);
  logActivity(req, {
    actionType: 'CREATE_GROUP', entityType: 'GROUP',
    entityId: group._id, entityName: group.name, academyId: group.academyId,
  });
  return sendSuccess(res, { data: group, message: 'تم إنشاء المجموعة بنجاح', statusCode: 201 });
};

// ─── PATCH /groups/:id ───────────────────────────────────────────────────────
const updateGroup = async (req, res, next) => {
  const group = await Group.findById(req.params.id);
  if (!group) return next(new AppError('المجموعة غير موجودة', 404));

  try {
    assertAccess(req, group, 'ليس لديك صلاحية لتعديل هذه المجموعة');
  } catch (err) {
    return next(err);
  }

  const allowedFields = ['name', 'ageGroup', 'capacity', 'coachId', 'isActive'];
  for (const field of allowedFields) {
    if (req.body[field] !== undefined) {
      group[field] = req.body[field];
    }
  }

  if (req.body.sportId !== undefined) {
    const chosen = String(req.body.sportId).trim();
    const academy = await Academy.findById(group.academyId).select('sports');
    const academySports = academy && Array.isArray(academy.sports) && academy.sports.length > 0
      ? academy.sports
      : ['كرة سلة'];
    if (chosen && !academySports.includes(chosen)) {
      return next(new AppError('الرياضة المختارة غير متاحة في هذه الأكاديمية', 422));
    }
    if (chosen) group.sportId = chosen;
  }

  await group.save();

  logActivity(req, {
    actionType: 'UPDATE_GROUP', entityType: 'GROUP',
    entityId: group._id, entityName: group.name, academyId: group.academyId,
  });
  return sendSuccess(res, { data: group, message: 'تم تحديث المجموعة بنجاح' });
};

// ─── DELETE /groups/:id ──────────────────────────────────────────────────────
const deleteGroup = async (req, res, next) => {
  const group = await Group.findById(req.params.id);
  if (!group) return next(new AppError('المجموعة غير موجودة', 404));

  try {
    assertAccess(req, group, 'ليس لديك صلاحية لحذف هذه المجموعة');
  } catch (err) {
    return next(err);
  }

  await Player.updateMany({ groupId: group._id }, { $set: { groupId: null } });
  await group.deleteOne();

  logActivity(req, {
    actionType: 'DELETE_GROUP', entityType: 'GROUP',
    entityId: group._id, entityName: group.name, academyId: group.academyId,
  });
  return sendSuccess(res, { message: 'تم حذف المجموعة بنجاح' });
};

module.exports = {
  getGroups,
  getGroupsByAcademy,
  getGroupsBySport,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
};
