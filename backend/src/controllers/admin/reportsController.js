const Report = require('../../models/Report');
const User = require('../../models/User');

// GET /api/admin/reports
const listReports = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, reportCategory, issueType, hasEvidence, assignedAdmin, awaiting_user, sort = 'createdAt:desc' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = {};
    if (status) {
      if (status === 'active') {
        // Filter out resolved and dismissed reports
        filter.status = { $nin: ['resolved', 'dismissed'] };
      } else {
        filter.status = status;
      }
    }
    if (reportCategory) filter.reportCategory = reportCategory;
    if (issueType) filter.issueType = issueType;
    if (assignedAdmin) filter.assignedAdmin = assignedAdmin;
    if (awaiting_user !== undefined) filter.status = awaiting_user === 'true' || awaiting_user === true ? 'awaiting_user' : filter.status;
    if (hasEvidence !== undefined) filter.evidence = hasEvidence === 'true' || hasEvidence === true ? { $exists: true, $ne: [] } : { $in: [[], null] };

    const [sortField, sortDir] = sort.split(':');
    const sortObj = { [sortField]: sortDir === 'asc' ? 1 : -1 };

    const reports = await Report.find(filter)
      .populate('reporter', 'firstName lastName email')
      .populate('assignedAdmin', 'firstName lastName email')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Report.countDocuments(filter);
    
    console.log('📋 Admin reports query:', {
      filter: filter,
      total: total,
      returned: reports.length,
      reports: reports.map(r => ({
        id: r._id,
        category: r.reportCategory,
        status: r.status,
        description: r.description?.substring(0, 50) + '...'
      }))
    });

    res.json({
      success: true,
      data: {
        reports,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / limit),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('Reports error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch reports' });
  }
};

// Allowed status transitions
const allowedTransitions = {
  pending: ['under_review', 'dismissed', 'resolved'],
  under_review: ['awaiting_user', 'investigating', 'resolved', 'dismissed'],
  awaiting_user: ['under_review', 'resolved', 'dismissed'],
  investigating: ['resolved', 'dismissed'],
  resolved: [],
  dismissed: []
};

// PUT /api/admin/reports/:reportId
const updateReport = async (req, res) => {
  try {
    const { reportId } = req.params;
  const { status, assignedAdmin, resolution, adminNote } = req.body;

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found' });
    }

    if (status && status !== report.status) {
      const allowed = allowedTransitions[report.status] || [];
      if (!allowed.includes(status)) {
        return res.status(400).json({ success: false, message: `Illegal status transition from ${report.status} to ${status}` });
      }
      const oldStatus = report.status;
      report.statusHistory.push({ from: report.status, to: status, by: req.user._id });
      report.status = status;
      
      // Notification service removed
    }
    if (assignedAdmin) {
      const User = require('../../models/User');
      const adminDoc = await User.findOne({ _id: assignedAdmin, role: 'admin' }).select('_id');
      if (!adminDoc) return res.status(400).json({ success: false, message: 'assignedAdmin must be a valid admin user id' });
      report.assignedAdmin = adminDoc._id;
    }
    if (resolution) {
      report.resolution = {
        ...report.resolution,
        ...resolution,
        resolvedBy: (report.status === 'resolved' || report.status === 'dismissed') ? req.user._id : report.resolvedBy,
        resolvedAt: (report.status === 'resolved' || report.status === 'dismissed') ? new Date() : report.resolvedAt
      };
    }
    if (adminNote) {
      report.adminNotes.push({ admin: req.user._id, note: adminNote });
    }

    await report.save();

    res.json({ success: true, message: 'Report updated successfully', data: report });
  } catch (error) {
    console.error('Update report error:', error);
    res.status(500).json({ success: false, message: 'Failed to update report' });
  }
};

// Specific actions
const requestInfo = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { message } = req.body;
    const report = await Report.findById(reportId);
    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });
    // Set awaiting_user
    if (report.status !== 'awaiting_user') {
      const allowed = allowedTransitions[report.status] || [];
      if (!allowed.includes('awaiting_user')) {
        return res.status(400).json({ success: false, message: `Illegal status transition from ${report.status} to awaiting_user` });
      }
      report.statusHistory.push({ from: report.status, to: 'awaiting_user', by: req.user._id });
      report.status = 'awaiting_user';
    }
    // Log an admin note with message
    report.adminNotes.push({ admin: req.user._id, note: `Request info: ${message}` });
    await report.save();
    res.json({ success: true, message: 'Info requested from reporter', data: report });
  } catch (error) {
    console.error('Request info error:', error);
    res.status(500).json({ success: false, message: 'Failed to request info' });
  }
};

const resolveReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { resolution } = req.body;
    const report = await Report.findById(reportId);
    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });
    const allowed = allowedTransitions[report.status] || [];
    if (!allowed.includes('resolved')) return res.status(400).json({ success: false, message: `Illegal status transition from ${report.status} to resolved` });
    report.statusHistory.push({ from: report.status, to: 'resolved', by: req.user._id });
    report.status = 'resolved';
    report.resolution = { ...(resolution || {}), resolvedBy: req.user._id, resolvedAt: new Date() };
    await report.save();
    res.json({ success: true, message: 'Report resolved', data: report });
  } catch (error) {
    console.error('Resolve report error:', error);
    res.status(500).json({ success: false, message: 'Failed to resolve report' });
  }
};

const dismissReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { resolution } = req.body;
    const report = await Report.findById(reportId);
    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });
    const allowed = allowedTransitions[report.status] || [];
    if (!allowed.includes('dismissed')) return res.status(400).json({ success: false, message: `Illegal status transition from ${report.status} to dismissed` });
    report.statusHistory.push({ from: report.status, to: 'dismissed', by: req.user._id });
    report.status = 'dismissed';
    report.resolution = { ...(resolution || {}), resolvedBy: req.user._id, resolvedAt: new Date() };
    await report.save();
    res.json({ success: true, message: 'Report dismissed', data: report });
  } catch (error) {
    console.error('Dismiss report error:', error);
    res.status(500).json({ success: false, message: 'Failed to dismiss report' });
  }
};

const stats = async (req, res) => {
  try {
    const { since, status, reportCategory, issueType, hasEvidence } = req.query;
    const match = {};
    if (since) match.createdAt = { $gte: new Date(since) };
    if (status) match.status = status;
    if (reportCategory) match.reportCategory = reportCategory;
    if (issueType) match.issueType = issueType;
    if (hasEvidence !== undefined) {
      match.evidence = hasEvidence === 'true' || hasEvidence === true 
        ? { $exists: true, $ne: [] } 
        : { $in: [[], null] };
    }

    const [byStatus, byCategory, byIssueType] = await Promise.all([
      Report.aggregate([{ $match: match }, { $group: { _id: '$status', count: { $sum: 1 } } }]),
      Report.aggregate([{ $match: match }, { $group: { _id: '$reportCategory', count: { $sum: 1 } } }]),
      Report.aggregate([{ $match: { ...match, reportCategory: 'user_issue' } }, { $group: { _id: '$issueType', count: { $sum: 1 } } }])
    ]);

    // Simple avg time to first response (status change from pending)
    const firstResponse = await Report.aggregate([
      { $match: match },
      { $unwind: '$statusHistory' },
      { $match: { 'statusHistory.from': 'pending' } },
      { $group: { _id: '$_id', firstAt: { $min: '$statusHistory.at' }, createdAt: { $first: '$createdAt' } } },
      { $project: { diffMs: { $subtract: ['$firstAt', '$createdAt'] } } },
      { $group: { _id: null, avgMs: { $avg: '$diffMs' } } }
    ]);

    res.json({ success: true, data: { byStatus, byCategory, byIssueType, avgTimeToFirstResponseMs: (firstResponse[0] && firstResponse[0].avgMs) || 0 } });
  } catch (error) {
    console.error('Reports stats error:', error);
    res.status(500).json({ success: false, message: 'Failed to get stats' });
  }
};

module.exports = { listReports, updateReport, requestInfo, resolveReport, dismissReport, stats };
