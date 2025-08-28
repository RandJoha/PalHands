const Report = require('../models/Report');
const NotificationService = require('../services/notificationService');

// POST /api/reports
const createReport = async (req, res) => {
  try {
    const { reportCategory = 'user_issue', reportedType, reportedId, reportedName, issueType, description, reportedUserRole, contactEmail, contactName, subject, requestedCategory, evidence = [], serviceName, categoryFit, importanceReason, partyInfo, ideaTitle, communityBenefit, device, os, appVersion, relatedBookingId, reportedServiceId, idempotencyKey: bodyIdemKey } = req.body;
    const headerIdemKey = req.get('Idempotency-Key');
    const idempotencyKey = bodyIdemKey || headerIdemKey;
    
    // Check if user is authenticated
    const isAuthenticated = req.user != null;
    
    // For certain categories, allow anonymous submissions
    const allowAnonymous = ['feature_suggestion', 'technical_issue', 'service_category_request', 'other'].includes(reportCategory);
    
    // For user_issue reports, require either authentication or valid contact info
    if (reportCategory === 'user_issue' && !isAuthenticated) {
      if (!contactEmail || !contactName) {
        return res.status(400).json({ 
          success: false, 
          message: 'Contact email and name are required for anonymous user issue reports.' 
        });
      }
    } else if (!isAuthenticated && !allowAnonymous) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required for this type of report. Please log in to submit user issue reports.' 
      });
    }
    
    // Idempotent create (optional) - only for authenticated users
    if (idempotencyKey && isAuthenticated) {
      const existing = await Report.findOne({ reporter: req.user._id, idempotencyKey });
      if (existing) return res.status(200).json({ success: true, message: 'Report already created', data: existing });
    }

    const reportData = {
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
    };

    // Add user info if authenticated
    if (isAuthenticated) {
      reportData.reporter = req.user._id;
      reportData.reporterRole = req.user.role;
    }

    const report = await Report.create(reportData);
    
    console.log('✅ Report created successfully:', {
      id: report._id,
      category: report.reportCategory,
      description: report.description,
      status: report.status,
      createdAt: report.createdAt
    });

    // Send notification to all admins about the new report
    try {
      await NotificationService.notifyNewReport(report);
    } catch (notificationError) {
      console.error('Failed to send notification for new report:', notificationError);
      // Don't fail the report creation if notification fails
    }

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
