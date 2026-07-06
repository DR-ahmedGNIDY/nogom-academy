const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema(
  {
    academyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Academy',
      required: [true, 'معرّف الأكاديمية مطلوب'],
    },
    // اسم الرياضة (نص حر، يطابق Academy.sports و Player.sport) — تنتمي كل
    // مجموعة لرياضة واحدة عندما تحتوي الأكاديمية على أكثر من رياضة.
    sportId: {
      type: String,
      trim: true,
      default: null,
    },
    coachId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Staff',
      default: null,
    },
    name: {
      type: String,
      required: [true, 'اسم المجموعة مطلوب'],
      trim: true,
      minlength: [2, 'اسم المجموعة يجب أن يكون حرفين على الأقل'],
      maxlength: [150, 'اسم المجموعة لا يمكن أن يتجاوز 150 حرف'],
    },
    ageGroup: {
      type: String,
      trim: true,
      maxlength: [60, 'الفئة العمرية لا يمكن أن تتجاوز 60 حرف'],
      default: null,
    },
    capacity: {
      type: Number,
      min: [1, 'السعة يجب أن تكون 1 على الأقل'],
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' },
    toJSON: {
      virtuals: true,
      transform: function (doc, ret) {
        ret._id = ret._id.toString();
        ret.academyId = ret.academyId?.toString();
        if (ret.coachId) ret.coachId = ret.coachId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

groupSchema.index({ academyId: 1 });
groupSchema.index({ academyId: 1, sportId: 1 });

const Group = mongoose.model('Group', groupSchema);
module.exports = Group;
