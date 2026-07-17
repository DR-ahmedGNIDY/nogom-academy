/**
 * التحقق من صلاحيات دور "مدرب" (coach) — يفحص تعريفات المسارات الفعلية.
 *
 * لا يعتمد على قوائم مكتوبة يدوياً: يحمّل ملفات الـ routes الحقيقية، يمشي على
 * express router stack، يتعرّف على middleware الناتج عن restrictTo عبر بصمة
 * كوده، ثم ينفّذه بـ req وهمي لكل دور ويسجّل السماح/المنع.
 *
 * التشغيل:  node scripts/verify_coach_permissions.js
 */

const path = require('path');

// restrictTo يُرجع closure بهذا الشكل — نتعرّف عليه ببصمة الكود.
const RESTRICT_TO_FINGERPRINT = 'roles.includes(req.user.role)';
const isRestrictTo = (fn) =>
  typeof fn === 'function' && fn.toString().includes(RESTRICT_TO_FINGERPRINT);

/** ينفّذ حارس restrictTo بـ req وهمي ويُرجع true إذا سمح. */
function guardAllows(guard, role) {
  let denied = false;
  const req = { user: { role, academyId: 'aca_1' }, query: {}, body: {}, params: {} };
  guard(req, {}, (err) => {
    if (err) denied = true;
  });
  return !denied;
}

/** يستخرج [{ method, path, guards }] من موديول router. */
function collectRoutes(router, mount) {
  const out = [];
  const routerLevelGuards = [];

  for (const layer of router.stack) {
    // طبقة middleware عامة على مستوى الراوتر: router.use(restrictTo(...))
    if (!layer.route) {
      if (isRestrictTo(layer.handle)) routerLevelGuards.push(layer.handle);
      continue;
    }
    for (const method of Object.keys(layer.route.methods)) {
      // مهم: router.route('/').get(a).post(restrictTo(..), b) يضع كل المعالجات
      // في نفس route.stack — لذا نُصفّي حسب الـ method وإلا تسرّبت حُرّاس POST
      // إلى GET وأعطت نتيجة خاطئة.
      const routeGuards = layer.route.stack
        .filter((s) => s.method === method)
        .map((s) => s.handle)
        .filter(isRestrictTo);

      // '/' على مستوى الراوتر يعني جذر المسار المركّب (مثلاً '/players')
      const full = (mount + layer.route.path).replace(/\/$/, '') || '/';
      out.push({
        method: method.toUpperCase(),
        path: full,
        // الحُرّاس على مستوى الراوتر تُطبَّق أولاً ثم حُرّاس المسار
        guards: [...routerLevelGuards, ...routeGuards],
      });
    }
  }
  return out;
}

const MODULES = [
  ['academy', '/academies'],
  ['user', '/users'],
  ['player', '/players'],
  ['subscription', '/subscriptions'],
  ['evaluation', '/evaluations'],
  ['dashboard', '/dashboard'],
  ['attendance', '/attendance'],
  ['staff', '/staff'],
  ['staffAttendance', '/staff-attendance'],
  ['payroll', '/payroll'],
  ['expense', '/expenses'],
  ['match', '/matches'],
  ['group', '/groups'],
  ['entryLog', '/entry-logs'],
];

const routes = [];
for (const [name, mount] of MODULES) {
  const mod = require(path.join(__dirname, '..', 'src', 'routes', `${name}.routes.js`));
  routes.push(...collectRoutes(mod, mount));
}

const allows = (method, routePath, role) => {
  const r = routes.find((x) => x.method === method && x.path === routePath);
  if (!r) throw new Error(`المسار غير موجود: ${method} ${routePath}`);
  return r.guards.every((g) => guardAllows(g, role));
};

// ─── المصفوفة المتوقّعة لدور coach ─────────────────────────────────────────
// ملاحظة: "مسموح" هنا تعني اجتياز restrictTo فقط. حصر الأكاديمية يُفرض داخل
// الـ controllers عبر req.user.academyId (يتحقق منه القسم الثاني أدناه).
const EXPECTED_COACH = [
  // يستطيع
  ['GET', '/players', true, 'عرض اللاعبين'],
  ['GET', '/players/search', true, 'البحث عن اللاعبين'],
  ['POST', '/players', true, 'إنشاء لاعب'],
  ['PUT', '/players/:id', true, 'تعديل لاعب'],
  ['PATCH', '/players/:id/change-group', true, 'نقل لاعب بين المجموعات'],
  ['POST', '/subscriptions', true, 'إنشاء/تجديد اشتراك'],
  ['GET', '/subscriptions/player/:playerId', true, 'عرض اشتراكات لاعب'],
  ['GET', '/groups', true, 'عرض المجموعات'],
  ['GET', '/groups/academy/:academyId', true, 'عرض مجموعات الأكاديمية'],
  ['POST', '/attendance', true, 'تسجيل/مسح حضور'],
  ['GET', '/attendance', true, 'عرض الحضور'],
  ['GET', '/attendance/report', true, 'تقرير الحضور'],
  ['GET', '/dashboard/stats', true, 'لوحة المدرب'],
  ['GET', '/academies', true, 'عرض أكاديميته (محصورة في الـ controller)'],

  // لا يستطيع
  ['DELETE', '/players/:id', false, 'حذف لاعب'],
  ['DELETE', '/players/:id/image', false, 'حذف صورة لاعب'],
  ['DELETE', '/subscriptions/:id', false, 'حذف اشتراك'],
  ['PATCH', '/subscriptions/:id/notes', false, 'تعديل اشتراك'],
  ['GET', '/subscriptions/academy/:academyId', false, 'اشتراكات الأكاديمية'],
  ['GET', '/subscriptions/academy/:academyId/revenue', false, 'إيرادات الأكاديمية'],
  ['GET', '/dashboard/revenue-by-month', false, 'الإيرادات الشهرية'],
  ['POST', '/groups', false, 'إنشاء مجموعة'],
  ['PATCH', '/groups/:id', false, 'تعديل مجموعة'],
  ['DELETE', '/groups/:id', false, 'حذف مجموعة'],
  ['POST', '/academies', false, 'إنشاء أكاديمية'],
  ['PUT', '/academies/:id', false, 'تعديل أكاديمية'],
  ['DELETE', '/academies/:id', false, 'حذف أكاديمية'],
  ['POST', '/users', false, 'إدارة المستخدمين'],
  ['GET', '/users/academy/:academyId', false, 'عرض المستخدمين'],
  ['GET', '/payroll', false, 'الرواتب'],
  ['GET', '/expenses', false, 'المصروفات'],
  ['GET', '/staff', false, 'الموظفون'],
  ['GET', '/evaluations/player/:playerId', false, 'عرض التقييمات'],
  ['POST', '/evaluations', false, 'إنشاء تقييم'],
  ['POST', '/matches', false, 'إنشاء مباراة'],
  ['PUT', '/matches/:id', false, 'تعديل مباراة'],
  ['DELETE', '/matches/:id', false, 'حذف مباراة'],
  // سجل الدخول محجوب تماماً عن المدرب.
  ['GET', '/entry-logs', false, 'سجل الدخول'],
  ['POST', '/entry-logs', false, 'إنشاء سجل دخول'],
  ['GET', '/entry-logs/stats', false, 'إحصائيات سجل الدخول'],
  ['GET', '/entry-logs/player/:playerId', false, 'سجل دخول لاعب'],
];

let failures = 0;
console.log('\n══ صلاحيات دور coach (من تعريفات المسارات الفعلية) ══\n');
for (const [method, p, expected, label] of EXPECTED_COACH) {
  let actual;
  try {
    actual = allows(method, p, 'coach');
  } catch (e) {
    console.log(`  ⚠️  ${e.message}`);
    failures++;
    continue;
  }
  const ok = actual === expected;
  if (!ok) failures++;
  const mark = ok ? '✅' : '❌';
  const verdict = actual ? 'مسموح' : 'ممنوع ';
  console.log(`  ${mark} ${verdict}  ${method.padEnd(6)} ${p.padEnd(42)} ${label}`);
}

// ─── عدم المساس بالأدوار الأخرى ────────────────────────────────────────────
// لقطة للسلوك المتوقّع للأدوار الموجودة على مسارات حسّاسة — يجب ألا تتغيّر.
const REGRESSION = [
  ['super_admin', 'DELETE', '/players/:id', true],
  ['super_admin', 'POST', '/academies', true],
  ['super_admin', 'GET', '/dashboard/revenue-by-month', true],
  ['supervisor', 'POST', '/players', true],
  ['supervisor', 'DELETE', '/subscriptions/:id', true],
  ['supervisor', 'GET', '/dashboard/revenue-by-month', true],
  ['supervisor', 'POST', '/academies', false],
  ['academy_admin', 'POST', '/players', true],
  ['academy_admin', 'PATCH', '/groups/:id', true],
  ['academy_admin', 'GET', '/dashboard/revenue-by-month', true],
  ['academy_admin', 'GET', '/subscriptions/academy/:academyId/revenue', true],
  ['academy_admin', 'DELETE', '/subscriptions/:id', false],
  // admin = صلاحية محدودة عامة عبر كل الأكاديميات — يجب أن يبقى كما هو
  ['admin', 'POST', '/players', true],
  ['admin', 'PUT', '/players/:id', true],
  ['admin', 'POST', '/subscriptions', true],
  ['admin', 'PATCH', '/players/:id/change-group', true],
  ['admin', 'GET', '/attendance/report', true],
  ['admin', 'DELETE', '/players/:id', false],
  ['admin', 'GET', '/subscriptions/academy/:academyId', false],
  ['security', 'GET', '/players', true],
  ['security', 'POST', '/attendance', true],
  ['security', 'POST', '/players', false],
  ['security', 'GET', '/dashboard/stats', false],
];

console.log('\n══ عدم المساس بالأدوار القائمة (regression) ══\n');
for (const [role, method, p, expected] of REGRESSION) {
  const actual = allows(method, p, role);
  const ok = actual === expected;
  if (!ok) failures++;
  console.log(
    `  ${ok ? '✅' : '❌'} ${role.padEnd(14)} ${method.padEnd(6)} ${p.padEnd(42)} ${actual ? 'مسموح' : 'ممنوع'}`
  );
}

// ─── سجل الدخول (Entry Logs): RBAC كامل لكل الأدوار ────────────────────────
// المسموح لهم: super_admin و academy_admin و security فقط.
// الإنشاء: super_admin و security فقط (مدير الأكاديمية عرض فقط).
const ENTRY_LOG_RBAC = [
  // super_admin — وصول كامل
  ['super_admin', 'GET', '/entry-logs', true],
  ['super_admin', 'POST', '/entry-logs', true],
  ['super_admin', 'GET', '/entry-logs/stats', true],
  ['super_admin', 'GET', '/entry-logs/player/:playerId', true],
  // security — يمسح ويُنشئ ويعرض
  ['security', 'GET', '/entry-logs', true],
  ['security', 'POST', '/entry-logs', true],
  ['security', 'GET', '/entry-logs/stats', true],
  ['security', 'GET', '/entry-logs/player/:playerId', true],
  // academy_admin — عرض فقط (لا إنشاء)
  ['academy_admin', 'GET', '/entry-logs', true],
  ['academy_admin', 'GET', '/entry-logs/stats', true],
  ['academy_admin', 'GET', '/entry-logs/player/:playerId', true],
  ['academy_admin', 'POST', '/entry-logs', false],
  // coach — ممنوع تماماً
  ['coach', 'GET', '/entry-logs', false],
  ['coach', 'POST', '/entry-logs', false],
  // admin (صلاحية محدودة) — ممنوع تماماً
  ['admin', 'GET', '/entry-logs', false],
  ['admin', 'POST', '/entry-logs', false],
  ['admin', 'GET', '/entry-logs/stats', false],
  // supervisor — ليس ضمن الأدوار المسموح لها
  ['supervisor', 'GET', '/entry-logs', false],
  ['supervisor', 'POST', '/entry-logs', false],
];

console.log('\n══ سجل الدخول (Entry Logs) — RBAC ══\n');
for (const [role, method, p, expected] of ENTRY_LOG_RBAC) {
  const actual = allows(method, p, role);
  const ok = actual === expected;
  if (!ok) failures++;
  console.log(
    `  ${ok ? '✅' : '❌'} ${role.padEnd(14)} ${method.padEnd(5)} ${p.padEnd(34)} ${actual ? 'مسموح' : 'ممنوع'}`
  );
}

// لا يجوز وجود أي مسار تعديل/حذف في وحدة سجل الدخول لأي دور.
const mutating = routes.filter(
  (r) => r.path.startsWith('/entry-logs') && ['PUT', 'PATCH', 'DELETE'].includes(r.method)
);
if (mutating.length > 0) {
  console.log(`  ❌ توجد مسارات تعديل/حذف في سجل الدخول: ${mutating.map((m) => `${m.method} ${m.path}`).join(', ')}`);
  failures++;
} else {
  console.log('\n  ✅ لا توجد أي مسارات PUT/PATCH/DELETE في سجل الدخول —');
  console.log('     التعديل والحذف وتغيير الطوابع الزمنية غير ممكنة بنيوياً.');
}

// ─── حصر الأكاديمية: coach يجب ألا يتجاوز فلترة الأكاديمية أبداً ───────────
// حصر النطاق في هذا المشروع يتم داخل الـ controllers عبر قوائم "الأدوار
// العامة" (super_admin / security / admin) التي تُمرِّر academyId من الطلب،
// وكل دور آخر يقع في فرع else الذي يفرض req.user.academyId (نفس فرع
// academy_admin تماماً — إعادة استخدام لا تكرار).
//
// لذلك السلامة تعتمد على شرط واحد: ألّا يُذكر 'coach' في أي شرط تجاوز.
// الاستثناء الوحيد المسموح: تصفير الإيرادات في dashboard.controller.
const fs = require('fs');
const CONTROLLERS_DIR = path.join(__dirname, '..', 'src', 'controllers');
const ALLOWED_COACH_MENTIONS = {
  'dashboard.controller.js': 2, // hideFinance + revenue في getSportStats
};

console.log('\n══ حصر الأكاديمية: لا تجاوز لفلترة الأكاديمية ══\n');
let scopeIssues = 0;
for (const file of fs.readdirSync(CONTROLLERS_DIR).filter((f) => f.endsWith('.js'))) {
  const src = fs.readFileSync(path.join(CONTROLLERS_DIR, file), 'utf8');
  // نعدّ إشارات coach داخل شروط الأدوار فقط (نتجاهل التعليقات)
  const codeLines = src
    .split('\n')
    .filter((l) => !l.trim().startsWith('//') && !l.trim().startsWith('*'));
  const mentions = codeLines.filter((l) => /role\s*[=!]==\s*'coach'/.test(l)).length;
  const allowed = ALLOWED_COACH_MENTIONS[file] || 0;
  if (mentions > allowed) {
    console.log(`  ❌ ${file}: ${mentions} إشارة إلى coach في شروط الأدوار (المسموح ${allowed})`);
    scopeIssues++;
    failures++;
  }
}
if (scopeIssues === 0) {
  console.log('  ✅ لا يظهر coach في أي شرط تجاوز نطاق داخل الـ controllers.');
  console.log('  ✅ إذاً coach يقع دائماً في فرع else ⇒ filter.academyId = req.user.academyId');
  console.log('     (نفس مسار academy_admin — بدون أي تكرار للمنطق).');
}

console.log(
  failures === 0
    ? '\n✅ كل الفحوصات نجحت — صلاحيات coach صحيحة والأدوار الأخرى لم تتغيّر.\n'
    : `\n❌ ${failures} فحص فشل.\n`
);
process.exit(failures === 0 ? 0 : 1);
