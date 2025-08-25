const SystemSetting = require('../../models/SystemSetting');

// GET /api/admin/settings
const listSettings = async (req, res) => {
  try {
    const settings = await SystemSetting.find().sort({ category: 1, key: 1 });
    res.json({ success: true, data: settings });
  } catch (error) {
    console.error('Settings error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch settings' });
  }
};

// PUT /api/admin/settings/:key
const updateSetting = async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;

    const setting = await SystemSetting.findOne({ key });
    if (!setting) {
      return res.status(404).json({ success: false, message: 'Setting not found' });
    }

    if (!setting.isEditable) {
      return res.status(403).json({ success: false, message: 'This setting cannot be modified' });
    }

    setting.value = value;
    setting.lastModifiedBy = req.user._id;
    await setting.save();

    res.json({ success: true, message: 'Setting updated successfully', data: setting });
  } catch (error) {
    console.error('Update setting error:', error);
    res.status(500).json({ success: false, message: 'Failed to update setting' });
  }
};

module.exports = { listSettings, updateSetting };
