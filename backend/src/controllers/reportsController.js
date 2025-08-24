const Report = require('../models/Report');

// POST /api/reports
const createReport = async (req, res) => {
  try {
  const { reportCategory = 'user_issue', reportedType, reportedId, reportedName, issueType, description, reportedUserRole, contactEmail, contactName, subject, requestedCategory, evidence = [], serviceName, categoryFit, importanceReason, partyInfo, ideaTitle, communityBenefit, device, os, appVersion, relatedBookingId, reportedServiceId, idempotencyKey: bodyIdemKey } = req.body;
    const headerIdemKey = req.get('Idempotency-Key');
    const idempotencyKey = bodyIdemKey || headerIdemKey;
    // Idempotent create (optional)
    if (idempotencyKey) {
      const existing = await Report.findOne({ reporter: req.user._id, idempotencyKey });
      if (existing) return res.status(200).json({ success: true, message: 'Report already created', data: existing });
    }

    const report = await Report.create({
      reporter: req.user._id,
      reporterRole: req.user.role,
      reportCategory,
  reportedType,
  reportedId,
  reportedUserRole,
  reportedName,
  issueType,
      description,
      contactEmail,
      contactName,
      subject,
  requestedCategory,
  serviceName,
  categoryFit,
  importanceReason,
  ideaTitle,
  communityBenefit,
  device,
  os,
  appVersion,
  partyInfo,
  relatedBookingId,
  reportedServiceId,
  idempotencyKey,
  evidence: Array.isArray(evidence) ? evidence : []
    });

    return res.status(201).json({ success: true, message: 'Report created', data: report });
  } catch (error) {
    console.error('Create report error:', error);
    return res.status(500).json({ success: false, message: 'Failed to create report' });
  }
};

// GET /api/reports/me
const listMyReports = async (req, res) => {
  try {
  const { page = 1, limit = 20, status, reportCategory, issueType, hasEvidence, createdFrom, createdTo } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = { reporter: req.user._id };
  if (status) filter.status = status;
  if (reportCategory) filter.reportCategory = reportCategory;
  if (issueType) filter.issueType = issueType;
  if (hasEvidence !== undefined) filter.evidence = hasEvidence === 'true' || hasEvidence === true ? { $exists: true, $ne: [] } : { $in: [[], null] };
  if (createdFrom || createdTo) {
    filter.createdAt = {};
    if (createdFrom) filter.createdAt.$gte = new Date(createdFrom);
    if (createdTo) filter.createdAt.$lte = new Date(createdTo);
  }

    const [items, total] = await Promise.all([
      Report.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Report.countDocuments(filter)
    ]);

    return res.json({
      success: true,
      data: {
        items,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / parseInt(limit)),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('List my reports error:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch reports' });
  }
};

// GET /api/reports/:id
const getReportById = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Report.findById(id);
    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });

    // Ownership: reporter or admin can view
    if (req.user.role !== 'admin' && report.reporter.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    return res.json({ success: true, data: report });
  } catch (error) {
    console.error('Get report error:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch report' });
  }
};

// POST /api/reports/:id/evidence (multipart)
const addEvidence = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Report.findById(id);
    if (!report) return res.status(404).json({ success: false, message: 'Report not found' });

    // Ownership: reporter or admin can attach evidence
    if (req.user.role !== 'admin' && report.reporter.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    const files = req.files || [];
    if (!files.length) {
      return res.status(400).json({ success: false, message: 'No files uploaded' });
    }

    const toAdd = files.map((f) => f.path.replace(/\\/g, '/'));
    report.evidence = [...(report.evidence || []), ...toAdd];
    await report.save();

    return res.status(200).json({ success: true, message: 'Evidence added', data: { evidence: report.evidence } });
  } catch (error) {
    console.error('Add evidence error:', error);
    return res.status(500).json({ success: false, message: 'Failed to add evidence' });
  }
};

module.exports = { createReport, listMyReports, getReportById, addEvidence };
