/* eslint-disable no-console */
// اختبار RBAC — صلاحيات Academy Admin على التقارير.
// يتحقق أن مدير الأكاديمية (academy_admin):
//   ✅ يستطيع الوصول لكل مصادر بيانات التقارير (dashboard/subscriptions/evaluations/attendance)
//      مقصورة على أكاديميته فقط
//   ❌ لا يستطيع إنشاء/تجديد اشتراك
//   ❌ لا يستطيع إنشاء مباراة أو إضافة لاعبين لها
//   ❌ لا يرى وحدات الإدارة المالية (الرواتب/المصروفات/الموظفين/المستخدمين)
// ينشئ بيانات اختبار مؤقتة، يفحص كل الصلاحيات، ثم يحذف كل ما أنشأه (مهما كانت النتيجة).
require('dotenv').config();
const mongoose = require('mongoose');

const Academy = require('../src/models/academy.model');
const User = require('../src/models/user.model');
const Player = require('../src/models/player.model');
const Subscription = require('../src/models/subscription.model');
const Evaluation = require('../src/models/evaluation.model');
const Attendance = require('../src/models/attendance.model');
const Match = require('../src/models/match.model');

const BASE = 'http://localhost:3999/api/v1';
const TAG = 'RBACREPORTTEST_' + Date.now();

let pass = 0, fail = 0;
const results = [];
function check(label, cond, detail) {
  if (cond) { pass++; results.push(`✅ ${label}`); }
  else { fail++; results.push(`❌ ${label}${detail ? ' — ' + detail : ''}`); }
}

async function api(path, { method = 'GET', token, body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  let json = null;
  try { json = await res.json(); } catch (_) {}
  return { status: res.status, body: json };
}

async function login(email, password) {
  const r = await api('/auth/login', { method: 'POST', body: { email, password } });
  if (r.status !== 200) throw new Error(`login failed for ${email}: ${JSON.stringify(r.body)}`);
  return r.body.token;
}

(async () => {
  await mongoose.connect(process.env.MONGODB_URI, { dbName: 'basketball_academy' });
  console.log('Connected to DB:', mongoose.connection.name);

  const createdAcademyIds = [];
  let matchAId = null;

  try {
    console.log('Seeding test fixtures...');

    // ─── بيانات الاختبار: أكاديمية A (تحت الاختبار) وأكاديمية B (للعزل) ───────
    const academyA = await Academy.create({ name: `${TAG}_ACADEMY_A`, phone: '0100000001', address: 'Test', currency: 'EGP' });
    createdAcademyIds.push(academyA._id);
    const academyB = await Academy.create({ name: `${TAG}_ACADEMY_B`, phone: '0100000002', address: 'Test', currency: 'EGP' });
    createdAcademyIds.push(academyB._id);

    const password = 'Test12345!';
    const academyAdminA = await User.create({ name: `${TAG}_ACAD_ADMIN_A`, email: `${TAG}_aa@test.com`.toLowerCase(), password, role: 'academy_admin', academyId: academyA._id });

    const playerA = await Player.create({ academyId: academyA._id, fullName: `${TAG}_PLAYER_A`, birthDate: '2010-01-01', parentName: 'ولي أمر A', parentRelationship: 'أب', parentPhone: '0111111111', sport: 'كرة سلة' });
    const playerB = await Player.create({ academyId: academyB._id, fullName: `${TAG}_PLAYER_B`, birthDate: '2010-01-01', parentName: 'ولي أمر B', parentRelationship: 'أب', parentPhone: '0122222222', sport: 'كرة سلة' });

    // بيانات فعلية داخل أكاديمية A حتى تُرجع نقاط التقارير محتوى حقيقياً
    await Subscription.create({ academyId: academyA._id, playerId: playerA._id, type: 'NEW_SUBSCRIPTION', amount: 500, startDate: new Date(), endDate: new Date(Date.now() + 30 * 86400000) });
    await Evaluation.create({ academyId: academyA._id, playerId: playerA._id, evaluatorId: academyAdminA._id, fitness: 6, basicSkills: 6, attack: 6, defense: 6, commitment: 6 });
    await Attendance.create({ playerId: playerA._id, academyId: academyA._id, sport: 'كرة سلة', date: '2026-01-01', time: '10:00', status: 'present' });

    // بيانات في أكاديمية B — للتأكد أن مدير أكاديمية A لا يراها
    const subB = await Subscription.create({ academyId: academyB._id, playerId: playerB._id, type: 'NEW_SUBSCRIPTION', amount: 900, startDate: new Date(), endDate: new Date(Date.now() + 30 * 86400000) });

    // مباراة موجودة مسبقاً في أكاديمية A (لاختبار "إضافة لاعبين لمباراة" الممنوعة)
    const matchA = await Match.create({ academyId: academyA._id, name: `${TAG}_MATCH_A`, location: 'ملعب الاختبار', date: '2026-08-01', time: '18:00' });
    matchAId = matchA._id;

    console.log(`Academy A: ${academyA._id}  |  Academy B: ${academyB._id}`);

    const tokenAcadA = await login(academyAdminA.email, password); // role: academy_admin, academy A

    // ═══════════════════════════════════════════════════════════════════════
    // 1) ✅ Academy Admin CAN access reports (scoped to own academy)
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api('/dashboard/stats', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/stats => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/revenue-by-month', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/revenue-by-month => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/subscriptions-by-type', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/subscriptions-by-type => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/players-by-birth-year', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/players-by-birth-year => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/evaluation-distribution', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/evaluation-distribution => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/recent-activities', { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/recent-activities => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/dashboard/sport-stats?sport=' + encodeURIComponent('كرة سلة'), { token: tokenAcadA });
      check('Academy Admin: GET /dashboard/sport-stats => 200 (تقارير رياضية)', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api(`/subscriptions/academy/${academyA._id}`, { token: tokenAcadA });
      check('Academy Admin: GET /subscriptions/academy/:ownId => 200 (تقارير الاشتراكات)', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api(`/subscriptions/academy/${academyA._id}/revenue`, { token: tokenAcadA });
      check('Academy Admin: GET /subscriptions/academy/:ownId/revenue => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api(`/evaluations/academy/${academyA._id}`, { token: tokenAcadA });
      check('Academy Admin: GET /evaluations/academy/:ownId => 200 (تقارير رياضية/تقييمات)', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/attendance/report', { token: tokenAcadA });
      check('Academy Admin: GET /attendance/report => 200 (تقارير الحضور)', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api('/attendance', { token: tokenAcadA });
      check('Academy Admin: GET /attendance => 200 (سجل الحضور)', r.status === 200, `got ${r.status}`);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2) ✅ Reports are scoped to own academy only (cannot see Academy B data)
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api(`/subscriptions/academy/${academyB._id}`, { token: tokenAcadA });
      check('Academy Admin: GET /subscriptions/academy/:otherAcademy => 403', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api(`/subscriptions/academy/${academyB._id}/revenue`, { token: tokenAcadA });
      check('Academy Admin: GET /subscriptions/academy/:otherAcademy/revenue => 403', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api(`/subscriptions/${subB._id}`, { token: tokenAcadA });
      check('Academy Admin: GET /subscriptions/:id (Academy B) => 403', r.status === 403, `got ${r.status}`);
    }
    {
      // evaluations/academy/:id يتجاهل الـ param كليّاً ويستخدم أكاديمية المستخدم دائماً
      const r = await api(`/evaluations/academy/${academyB._id}`, { token: tokenAcadA });
      const ids = (r.body?.data || []).map((e) => e.academyId?.toString?.() || e.academyId);
      check('Academy Admin: GET /evaluations/academy/:otherAcademy لا يُرجع بيانات B', !ids.includes(academyB._id.toString()));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3) ❌ Academy Admin CANNOT create / renew subscriptions
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api('/subscriptions', {
        method: 'POST', token: tokenAcadA,
        body: { playerId: playerA._id.toString(), type: 'NEW_SUBSCRIPTION', amount: 100, startDate: '2026-01-01', endDate: '2026-02-01' },
      });
      check('Academy Admin: POST /subscriptions (NEW_SUBSCRIPTION) => 403 (لا يستطيع إنشاء اشتراك)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/subscriptions', {
        method: 'POST', token: tokenAcadA,
        body: { playerId: playerA._id.toString(), type: 'RENEWAL', amount: 100, startDate: '2026-01-01', endDate: '2026-02-01' },
      });
      check('Academy Admin: POST /subscriptions (RENEWAL) => 403 (لا يستطيع تجديد اشتراك)', r.status === 403, `got ${r.status}`);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 4) ❌ Academy Admin CANNOT create matches / add players to matches
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api('/matches', {
        method: 'POST', token: tokenAcadA,
        body: { name: `${TAG}_MATCH_NEW`, location: 'ملعب', date: '2026-09-01', time: '18:00' },
      });
      check('Academy Admin: POST /matches => 403 (لا يستطيع إنشاء مباراة)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api(`/matches/${matchAId}/players`, {
        method: 'POST', token: tokenAcadA,
        body: { playerIds: [playerA._id.toString()] },
      });
      check('Academy Admin: POST /matches/:id/players => 403 (لا يستطيع إضافة لاعبين للمباراة)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api(`/matches/${matchAId}`, { token: tokenAcadA });
      check('Academy Admin: GET /matches/:id => 200 (يستطيع المشاهدة فقط)', r.status === 200, `got ${r.status}`);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 5) ❌ Financial / staff / user-management modules hidden
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api('/payroll', { token: tokenAcadA });
      check('Academy Admin: GET /payroll => 403 (لا يرى الرواتب)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/payroll/report?month=2026-01', { token: tokenAcadA });
      check('Academy Admin: GET /payroll/report => 403 (لا يرى تقرير الرواتب)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/expenses', { token: tokenAcadA });
      check('Academy Admin: GET /expenses => 403 (لا يرى المصروفات)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/expenses/report?startDate=2026-01-01&endDate=2026-01-31', { token: tokenAcadA });
      check('Academy Admin: GET /expenses/report => 403 (لا يرى تقرير المصروفات)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/staff', { token: tokenAcadA });
      check('Academy Admin: GET /staff => 403 (لا يرى الموظفين)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/staff-attendance', { token: tokenAcadA });
      check('Academy Admin: GET /staff-attendance => 403 (لا يرى حضور الموظفين)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/users', {
        method: 'POST', token: tokenAcadA,
        body: { name: 'X', email: `${TAG}_hacker@test.com`, password: 'Test12345!', academyId: academyA._id.toString() },
      });
      check('Academy Admin: POST /users => 403 (لا يستطيع إدارة المستخدمين)', r.status === 403, `got ${r.status}`);
    }
    {
      const r = await api('/academies', {
        method: 'POST', token: tokenAcadA,
        body: { name: `${TAG}_NEW_ACADEMY`, phone: '0100000009', address: 'Test' },
      });
      check('Academy Admin: POST /academies => 403 (لا يستطيع إنشاء أكاديمية جديدة)', r.status === 403, `got ${r.status}`);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 6) POSITIVE CONTROL — Academy Admin CAN still view players/own academy
    // ═══════════════════════════════════════════════════════════════════════
    {
      const r = await api(`/players/${playerA._id}`, { token: tokenAcadA });
      check('POSITIVE: Academy Admin: GET own Player A => 200', r.status === 200, `got ${r.status}`);
    }
    {
      const r = await api(`/academies/${academyA._id}`, { token: tokenAcadA });
      check('POSITIVE: Academy Admin: GET own Academy A => 200', r.status === 200, `got ${r.status}`);
    }

  } catch (err) {
    console.error('FATAL TEST ERROR:', err);
    fail++;
    results.push(`❌ FATAL: ${err.message}`);
  } finally {
    console.log('\nCleaning up test fixtures...');
    if (matchAId) {
      await Match.deleteMany({ _id: matchAId });
      await Match.deleteMany({ name: `${TAG}_MATCH_NEW` });
    }
    if (createdAcademyIds.length) {
      await Attendance.deleteMany({ academyId: { $in: createdAcademyIds } });
      await Evaluation.deleteMany({ academyId: { $in: createdAcademyIds } });
      await Subscription.deleteMany({ academyId: { $in: createdAcademyIds } });
      await Player.deleteMany({ academyId: { $in: createdAcademyIds } });
      await User.deleteMany({ academyId: { $in: createdAcademyIds } });
      await Academy.deleteMany({ _id: { $in: createdAcademyIds } });

      const leftoverCheck = await Promise.all([
        Academy.countDocuments({ _id: { $in: createdAcademyIds } }),
        User.countDocuments({ academyId: { $in: createdAcademyIds } }),
        Player.countDocuments({ academyId: { $in: createdAcademyIds } }),
      ]);
      console.log(`Cleanup verification (should be 0,0,0): ${leftoverCheck.join(',')}`);
    }

    console.log('\n========== RESULTS ==========');
    results.forEach((r) => console.log(r));
    console.log('================================');
    console.log(`PASS: ${pass}  FAIL: ${fail}  TOTAL: ${pass + fail}`);

    await mongoose.disconnect();
    process.exit(fail > 0 ? 1 : 0);
  }
})();
