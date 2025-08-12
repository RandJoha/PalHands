const AdminAction = require('../../models/AdminAction');

// GET /api/admin/actions
const listActions = async (req, res) => {
  try {
    const { page = 1, limit = 50, adminId, action, startDate, endDate } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (adminId) filter.admin = adminId;
    if (action) filter.action = action;
    if (startDate || endDate) {
      filter.timestamp = {};
      if (startDate) filter.timestamp.$gte = new Date(startDate);
      if (endDate) filter.timestamp.$lte = new Date(endDate);
    }

    const actions = await AdminAction.find(filter)
      .populate('admin', 'firstName lastName email')
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await AdminAction.countDocuments(filter);

    res.json({
      success: true,
      data: {
        actions,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / limit),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('Actions log error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch actions log' });
  }
};

module.exports = { listActions };
