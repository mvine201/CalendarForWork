const mongoose = require('mongoose');

const priorities = ['low', 'normal', 'high', 'urgent'];
const statuses = ['new', 'in_progress', 'done'];
const priorityWeights = {
  low: 1,
  normal: 2,
  high: 3,
  urgent: 4
};

const taskSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 160
    },
    priority: {
      type: String,
      enum: priorities,
      default: 'normal',
      index: true
    },
    priorityRank: {
      type: Number,
      default: priorityWeights.normal,
      index: true
    },
    description: {
      type: String,
      trim: true,
      maxlength: 4000,
      default: ''
    },
    time: {
      hour: { type: Number, min: 0, max: 23, required: true },
      minute: { type: Number, min: 0, max: 59, required: true },
      day: { type: Number, min: 1, max: 31, required: true },
      month: { type: Number, min: 1, max: 12, required: true },
      year: { type: Number, min: 1970, max: 3000, required: true }
    },
    durationMinutes: {
      type: Number,
      min: 1,
      max: 10080,
      default: 60
    },
    dueAt: {
      type: Date,
      required: true,
      index: true
    },
    status: {
      type: String,
      enum: statuses,
      default: 'new',
      index: true
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

taskSchema.index({ user: 1, status: 1, dueAt: 1 });
taskSchema.index({ user: 1, priorityRank: -1, dueAt: 1 });

taskSchema.pre('validate', function setPriorityRank(next) {
  this.priorityRank = priorityWeights[this.priority] || priorityWeights.normal;
  next();
});

module.exports = {
  Task: mongoose.model('Task', taskSchema),
  priorities,
  statuses,
  priorityWeights
};
