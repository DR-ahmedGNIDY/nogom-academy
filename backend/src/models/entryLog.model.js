const mongoose = require('mongoose');

// ─── سجل دخول اللاعب (Player Entry Log) ──────────────────────────────────────
//
// وحدة مستقلة تماماً عن "حضور التدريب" (Attendance):
//   • Attendance = حضور التدريب (يسجّله المدرب/الإداري، سجل واحد لكل يوم).
//   • EntryLog   = دخول اللاعب من البوابة (يسجّله الأمن، عند كل دخول).
//
// لا تُشارك هذه المجموعة أي بيانات مع مجموعة attendance، ولا يوجد أي اعتماد
// متبادل بينهما.
//
// ملاحظة تصميمية مقصودة: لا يوجد فهرس فريد على (playerId, entryDate) — فاللاعب
// قد يدخل ويخرج ويعود في اليوم نفسه، وكل دخول حدث مستقل يجب أن يُسجَّل. هذا
// يخالف عمداً سلوك Attendance الذي يمنع التكرار اليومي.
const entryLogSchema = new mongoose.Schema(
  {
    // ── الأكاديمية ──────────────────────────────────────────────────────────
    academyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Academy',
      required: [true, 'معرّف الأكاديمية مطلوب'],
    },
    // لقطة (snapshot) من اسم الأكاديمية وقت الدخول — يبقى السجل التاريخي صحيحاً
    // حتى لو أُعيدت تسمية الأكاديمية أو حُذفت لاحقاً.
    academyName: {
      type: String,
      trim: true,
      default: '',
    },

    // ── اللاعب ──────────────────────────────────────────────────────────────
    playerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Player',
      required: [true, 'معرّف اللاعب مطلوب'],
    },
    playerCode: {
      type: String,
      trim: true,
      required: [true, 'كود اللاعب مطلوب'],
    },
    playerName: {
      type: String,
      trim: true,
      required: [true, 'اسم اللاعب مطلوب'],
    },

    // ── المجموعة والرياضة (لقطة وقت الدخول) ─────────────────────────────────
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      default: null,
    },
    groupName: {
      type: String,
      trim: true,
      default: null,
    },
    sport: {
      type: String,
      trim: true,
      default: null,
    },

    // ── زمن الدخول ──────────────────────────────────────────────────────────
    // تُولَّد كلها في الخادم فقط. لا تُقبل أي قيمة زمنية من العميل حتى لا
    // يستطيع الأمن التلاعب بوقت الدخول (متطلّب: Security CANNOT modify timestamps).
    entryDate: {
      type: String,
      required: [true, 'تاريخ الدخول مطلوب'],
      match: [/^\d{4}-\d{2}-\d{2}$/, 'صيغة التاريخ غير صحيحة'],
    },
    entryTime: {
      type: String,
      required: [true, 'وقت الدخول مطلوب'],
      match: [/^\d{2}:\d{2}$/, 'صيغة الوقت غير صحيحة'],
    },
    entryTimestamp: {
      type: Date,
      required: true,
      default: Date.now,
    },

    // ── طريقة الدخول ────────────────────────────────────────────────────────
    entryMethod: {
      type: String,
      enum: {
        values: ['QR', 'MANUAL'],
        message: 'طريقة الدخول غير صحيحة',
      },
      required: [true, 'طريقة الدخول مطلوبة'],
      default: 'QR',
    },

    // ── من سجّل الدخول (لقطة وقت الدخول) ────────────────────────────────────
    securityUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'معرّف المستخدم مطلوب'],
    },
    securityUserName: {
      type: String,
      trim: true,
      default: '',
    },

    // ── حقول اختيارية ───────────────────────────────────────────────────────
    deviceInfo: {
      type: String,
      trim: true,
      maxlength: [200, 'معلومات الجهاز لا يمكن أن تتجاوز 200 حرف'],
      default: null,
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [500, 'الملاحظات لا يمكن أن تتجاوز 500 حرف'],
      default: null,
    },
  },
  {
    // createdAt / updatedAt بالصيغة الافتراضية (تختلف عن attendance التي تستخدم
    // created_at/updated_at) — الوحدتان مستقلتان تماماً.
    timestamps: true,
    toJSON: {
      transform: function (doc, ret) {
        ret._id = ret._id.toString();
        ret.academyId = ret.academyId?.toString();
        if (ret.playerId && ret.playerId._id) {
          ret.playerId._id = ret.playerId._id.toString();
        } else if (ret.playerId) {
          ret.playerId = ret.playerId.toString();
        }
        if (ret.groupId) ret.groupId = ret.groupId.toString();
        if (ret.securityUserId) ret.securityUserId = ret.securityUserId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// ─── الفهارس ─────────────────────────────────────────────────────────────────
// سجل اليوم / الفلترة بالتاريخ لكل أكاديمية (الاستعلام الأكثر شيوعاً).
entryLogSchema.index({ academyId: 1, entryDate: -1 });
// تبويب "سجل الدخول" داخل صفحة اللاعب.
entryLogSchema.index({ playerId: 1, entryTimestamp: -1 });
// الترتيب الزمني العام (super_admin عبر كل الأكاديميات).
entryLogSchema.index({ entryTimestamp: -1 });
// الفلترة حسب المجموعة + إحصائية "أكثر المجموعات نشاطاً".
entryLogSchema.index({ academyId: 1, groupId: 1, entryDate: -1 });
// البحث بكود اللاعب.
entryLogSchema.index({ playerCode: 1 });

const EntryLog = mongoose.model('EntryLog', entryLogSchema);
module.exports = EntryLog;
