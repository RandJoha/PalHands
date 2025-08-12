const Report = require('../../models/Report');

// GET /api/admin/reports
const listReports = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, priority } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (status) filter.status = status;
    if (priority) filter.priority = priority;

    const reports = await Report.find(filter)
      .populate('reporter', 'firstName lastName email')
      .populate('assignedAdmin', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Report.countDocuments(filter);

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

// PUT /api/admin/reports/:reportId
const updateReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { status, assignedAdmin, resolution, adminNote } = req.body;

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found' });
    }

    if (status) report.status = status;
    if (assignedAdmin) report.assignedAdmin = assignedAdmin;
    if (resolution) report.resolution = resolution;
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

module.exports = { listReports, updateReport };
