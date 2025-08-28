import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/reports_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/app_toast.dart';

class ReportsWidget extends StatefulWidget {
  const ReportsWidget({super.key});

  @override
  State<ReportsWidget> createState() => _ReportsWidgetState();
}

class _ReportsWidgetState extends State<ReportsWidget> {
  final ReportsService _reportsService = ReportsService();
  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedIssueType;
  bool? _hasEvidence;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  static const int _pageLimit = 100; // Number of reports per page - increased to show all reports
  
  // Stats
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔄 ReportsWidget initializing...');
    }
    // Don't load reports immediately - let the build method handle authentication check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadReports();
    });
  }

  void _checkAuthAndLoadReports() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (kDebugMode) {
      print('🔍 Checking auth status - Auth: ${authService.isAuthenticated}, Admin: ${authService.isAdmin}');
    }
    
    if (authService.isAuthenticated && authService.isAdmin) {
      if (kDebugMode) {
        print('✅ User is authenticated as admin, loading reports...');
      }
      _loadReports();
      _loadStats();
    } else {
      if (kDebugMode) {
        print('❌ User not authenticated as admin - Auth: ${authService.isAuthenticated}, Admin: ${authService.isAdmin}');
        print('❌ Will NOT load reports - user needs to authenticate first');
      }
      // Don't load reports if not authenticated - let the UI show the auth prompt
    }
  }

  Future<void> _loadReports() async {
    // Safety check - don't load reports if not authenticated as admin
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated || !authService.isAdmin) {
      if (kDebugMode) {
        print('🛑 Blocked report loading - user not authenticated as admin');
      }
      return;
    }
    
    if (kDebugMode) {
      print('📋 Starting to load reports...');
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        print('📋 Calling reportsService.listAllReports...');
      }
      
      final auth = Provider.of<AuthService>(context, listen: false);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      };

      if (kDebugMode) {
        print('🔐 Using headers for reports: $headers');
      }

      // Filter out resolved and dismissed reports by default unless specifically requested
      String? effectiveStatus = _selectedStatus;
      if (_selectedStatus == null || _selectedStatus!.isEmpty) {
        // Show only active reports (not resolved or dismissed) by default
        effectiveStatus = 'active';
      }
      
      final response = await _reportsService.listAllReports(
        page: _currentPage,
        limit: _pageLimit,
        status: effectiveStatus,
        reportCategory: _selectedCategory,
        issueType: _selectedIssueType,
        hasEvidence: _hasEvidence,
        headersOverride: headers,
      );

      if (kDebugMode) {
        print('📋 Reports response: ${response.toString()}');
      }

      if (response['success'] == true) {
        final reports = response['data']['reports'] as List<ReportModel>;
        final pagination = response['data']['pagination'] as Map<String, dynamic>;
        
        if (kDebugMode) {
          print('✅ Successfully loaded ${reports.length} reports');
          print('📊 Pagination: $pagination');
        }
        
        setState(() {
          _reports = reports;
          _totalPages = pagination['total'];
          _totalRecords = pagination['totalRecords'];
          _isLoading = false;
        });
      } else {
        final errorMessage = response['message'] ?? 'Failed to load reports';
        if (kDebugMode) {
          print('❌ Failed to load reports: $errorMessage');
        }
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception loading reports: $e');
      }
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      };
      
      // Build query parameters based on current filters
      final queryParams = <String, String>{};
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) queryParams['status'] = _selectedStatus!;
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) queryParams['reportCategory'] = _selectedCategory!;
      if (_selectedIssueType != null && _selectedIssueType!.isNotEmpty) queryParams['issueType'] = _selectedIssueType!;
      if (_hasEvidence != null) queryParams['hasEvidence'] = _hasEvidence.toString();
      
      final response = await _reportsService.getReportsStats(
        headersOverride: headers,
        queryParams: queryParams,
      );
      if (response['success'] == true) {
        setState(() {
          _stats = response['data'];
        });
      }
    } catch (e) {
      // Stats loading failure shouldn't block the main UI
      if (mounted) {
        AppToast.show(context, message: 'Failed to load statistics', type: AppToastType.warning);
      }
    }
  }

  Future<void> _updateReport(String reportId, {
    String? status,
    String? adminNote,
  }) async {
    try {
      final response = await _reportsService.updateReport(
        reportId,
        status: status,
        adminNote: adminNote,
      );

      if (response['success'] == true) {
        AppToast.show(context, message: 'Report updated successfully', type: AppToastType.success);
        _loadReports(); // Refresh the list
      } else {
        AppToast.show(context, message: response['message'] ?? 'Failed to update report', type: AppToastType.error);
      }
    } catch (e) {
      AppToast.show(context, message: 'Network error: $e', type: AppToastType.error);
    }
  }



  Future<void> _editReport(String reportId) async {
    // Find the current report to get its status
    final currentReport = _reports.firstWhere((r) => r.id == reportId);
    final currentStatus = currentReport.status;
    
    if (kDebugMode) {
      print('🔍 Current report status: $currentStatus');
    }
    
    final status = await _showEditDialog(currentStatus);
    if (kDebugMode) {
      print('🔍 Selected status: $status');
    }
    
    if (status != null && status != currentStatus) {
      try {
        if (kDebugMode) {
          print('🔄 Updating report $reportId from $currentStatus to status: $status');
        }
        
        // Get authentication headers
        final auth = Provider.of<AuthService>(context, listen: false);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
        };

        if (kDebugMode) {
          print('🔐 Using headers for update: $headers');
        }
        
        final response = await _reportsService.updateReport(
          reportId,
          status: status,
          headersOverride: headers,
        );

        if (kDebugMode) {
          print('📋 Update response: $response');
        }

        if (response['success'] == true) {
          AppToast.show(context, message: 'Report updated successfully', type: AppToastType.success);
          
          // If the report was resolved or dismissed, remove it from the list immediately
          if (status == 'resolved' || status == 'dismissed') {
            setState(() {
              _reports.removeWhere((report) => report.id == reportId);
              // Don't decrease totalRecords - keep total count of all reports
            });
          }
          
          _loadStats(); // Reload stats to update the cards
        } else {
          final errorMessage = response['message'] ?? 'Failed to update report';
          if (kDebugMode) {
            print('❌ Update failed: $errorMessage');
          }
          AppToast.show(context, message: errorMessage, type: AppToastType.error);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Update exception: $e');
        }
        AppToast.show(context, message: 'Network error: $e', type: AppToastType.error);
      }
    } else if (status == currentStatus) {
      AppToast.show(context, message: 'Status unchanged', type: AppToastType.info);
    } else if (status == null) {
      if (kDebugMode) {
        print('❌ No status selected (user cancelled)');
      }
    }
  }





  Future<String?> _showEditDialog(String currentStatus) async {
    String selectedStatus = currentStatus;
    
    // Define allowed status transitions based on backend rules
    final allowedTransitions = {
      'pending': ['under_review', 'dismissed', 'resolved'],
      'under_review': ['awaiting_user', 'investigating', 'resolved', 'dismissed'],
      'awaiting_user': ['under_review', 'resolved', 'dismissed'],
      'investigating': ['resolved', 'dismissed'],
      'resolved': [],
      'dismissed': []
    };
    
    // Get valid transitions for current status
    final validTransitions = allowedTransitions[currentStatus] ?? [];
    final allStatuses = ['pending', 'under_review', 'resolved', 'dismissed'];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8F0), // Light peach/orange background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Edit Report Status', 
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF2C3E50), // Dark gray text
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select new status:', 
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF2C3E50), // Dark gray text
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2C3E50)), // Dark gray border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2C3E50)), // Dark gray border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE67E22), width: 2), // Orange focus border
                ),
                labelStyle: GoogleFonts.cairo(
                  color: const Color(0xFF2C3E50), // Dark gray label
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.cairo(
                color: const Color(0xFF2C3E50), // Dark gray text
              ),
              items: [
                // Current status (always available)
                DropdownMenuItem(
                  value: currentStatus,
                  child: Row(
                    children: [
                      Text(_getStatusDisplayName(currentStatus)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Valid transitions
                ...validTransitions.map((status) => DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Text(_getStatusDisplayName(status)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Valid',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                // Invalid transitions (disabled)
                ...allStatuses
                    .where((status) => status != currentStatus && !validTransitions.contains(status))
                    .map((status) => DropdownMenuItem(
                      value: status,
                      enabled: false,
                      child: Row(
                        children: [
                          Text(
                            _getStatusDisplayName(status),
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Invalid',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              onChanged: (value) {
                selectedStatus = value ?? 'pending';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.cairo(
                color: const Color(0xFFE67E22), // Reddish-brown text
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22), // Reddish-brown background
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Update',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, AuthService>(
      builder: (context, languageService, authService, child) {
        // Check if user is authenticated as admin
        if (!authService.isAuthenticated || !authService.isAdmin) {
          return _buildAuthenticationPrompt(authService);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.getString('reportsAndDisputes', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AppStrings.getString('adminDashboard', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            if (_stats != null) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildStatsCards(),
            ),
            if (_stats != null) const SizedBox(height: 12),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildFilters(),
            ),
            const SizedBox(height: 12),

            // Reports Table - Takes remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildReportsTable(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Reports',
            _totalRecords.toString(),
            Icons.report,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending',
            _stats?['byStatus']?.firstWhere((s) => s['_id'] == 'pending', orElse: () => {'count': 0})['count']?.toString() ?? '0',
            Icons.pending,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Resolved',
            _stats?['byStatus']?.firstWhere((s) => s['_id'] == 'resolved', orElse: () => {'count': 0})['count']?.toString() ?? '0',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Dismissed',
            _stats?['byStatus']?.firstWhere((s) => s['_id'] == 'dismissed', orElse: () => {'count': 0})['count']?.toString() ?? '0',
            Icons.cancel,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Active Reports')),
                const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                const DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                const DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _currentPage = 1;
                });
                _checkAuthAndLoadReports();
              },
            ),
          ),


          // Category Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                const DropdownMenuItem(value: 'user_issue', child: Text('User Issue')),
                const DropdownMenuItem(value: 'technical_issue', child: Text('Technical Issue')),
                const DropdownMenuItem(value: 'feature_suggestion', child: Text('Feature Suggestion')),
                const DropdownMenuItem(value: 'service_category_request', child: Text('Service Category Request')),
                const DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _currentPage = 1;
                });
                _checkAuthAndLoadReports();
              },
            ),
          ),
          const SizedBox(width: 16),

          // Refresh Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _checkAuthAndLoadReports,
            icon: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkAuthAndLoadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Reporter', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF6C757D)))),
                Expanded(flex: 2, child: Text('Category', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF6C757D)))),
                Expanded(flex: 2, child: Text('Status', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF6C757D)))),
                Expanded(flex: 2, child: Text('Date', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF6C757D)))),
                Expanded(flex: 2, child: Text('Actions', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF6C757D)))),
              ],
            ),
          ),

          // Table Body - Takes remaining space
          Expanded(
            child: ListView.separated(
              itemCount: _reports.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE9ECEF)),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _buildReportRow(report, index);
              },
            ),
          ),

          // Pagination
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildReportRow(ReportModel report, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Reporter (with avatar-like design)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getReporterColor(report.contactName ?? report.reporter?['firstName'] ?? 'U'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getReporterInitial(report.contactName ?? report.reporter?['firstName'] ?? 'Unknown'),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.contactName ?? 
                        (report.reporter?['firstName'] != null 
                            ? '${report.reporter!['firstName']} ${report.reporter!['lastName']}'
                            : 'Anonymous'),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF212529),
                        ),
                      ),
                      Text(
                        report.contactEmail ?? report.reporter?['email'] ?? 'No email',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(report.reportCategory),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryDisplayName(report.reportCategory),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBadgeColor(report.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusDisplayName(report.status).toUpperCase(),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),



          // Date
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(report.createdAt),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: const Color(0xFF6C757D),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showReportDetails(report),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View Details',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _editReport(report.id),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Status',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${((_currentPage - 1) * _pageLimit) + 1}-${(_currentPage * _pageLimit).clamp(1, _totalRecords)} of $_totalRecords reports',
            style: GoogleFonts.cairo(
              fontSize: 14, 
              color: const Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDEE2E6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: _currentPage > 1 ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _checkAuthAndLoadReports();
                  } : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: _currentPage > 1 ? Colors.white : Colors.grey.shade100,
                    foregroundColor: _currentPage > 1 ? const Color(0xFF495057) : const Color(0xFF6C757D),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDEE2E6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: _currentPage < _totalPages ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _checkAuthAndLoadReports();
                  } : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: _currentPage < _totalPages ? Colors.white : Colors.grey.shade100,
                    foregroundColor: _currentPage < _totalPages ? const Color(0xFF495057) : const Color(0xFF6C757D),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Reporter', _getReporterDisplayName(report)),
              _buildDetailRow('Email', _getReporterEmail(report)),
              _buildDetailRow('Category', _getCategoryDisplayName(report.reportCategory)),
              _buildDetailRow('Status', _getStatusDisplayName(report.status)),
              // Show title for "Other" reports, idea title for feature suggestions
              if (report.reportCategory == 'other' && report.subject != null && report.subject!.isNotEmpty) 
                _buildDetailRow('Title', report.subject!),
              if (report.reportCategory == 'feature_suggestion' && report.ideaTitle != null && report.ideaTitle!.isNotEmpty) 
                _buildDetailRow('Idea Title', report.ideaTitle!),
              if (report.issueType != null) _buildDetailRow('Issue Type', _getIssueTypeDisplayName(report.issueType!)),
              if (report.reportedName != null && report.reportedName!.isNotEmpty) _buildDetailRow('Reported Name', report.reportedName!),
              if (report.serviceName != null && report.serviceName!.isNotEmpty) _buildDetailRow('Service Name', report.serviceName!),
              // Show description for all reports
              _buildDetailRow('Description', report.description.isNotEmpty ? report.description : 'No description provided'),
              if (report.adminNote != null && report.adminNote!.isNotEmpty) _buildDetailRow('Admin Note', report.adminNote!),
              if (report.resolution != null && report.resolution!.isNotEmpty) _buildDetailRow('Resolution', report.resolution!),
              _buildDetailRow('Created', _formatDate(report.createdAt)),
              _buildDetailRow('Updated', _formatDate(report.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _getReporterDisplayName(ReportModel report) {
    // First try to get from contactName
    if (report.contactName != null && report.contactName!.isNotEmpty) {
      return report.contactName!;
    }
    
    // Then try to get from reporter object
    if (report.reporter != null) {
      final firstName = report.reporter!['firstName']?.toString() ?? '';
      final lastName = report.reporter!['lastName']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '${firstName} ${lastName}'.trim();
      }
    }
    
    // Fallback to anonymous
    return 'Anonymous';
  }

  String _getReporterEmail(ReportModel report) {
    // First try to get from contactEmail
    if (report.contactEmail != null && report.contactEmail!.isNotEmpty) {
      return report.contactEmail!;
    }
    
    // Then try to get from reporter object
    if (report.reporter != null) {
      final email = report.reporter!['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    
    // Fallback
    return 'No email provided';
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'user_issue': return 'User Issue';
      case 'technical_issue': return 'Technical Issue';
      case 'feature_suggestion': return 'Feature Suggestion';
      case 'service_category_request': return 'Service Category Request';
      case 'other': return 'Other';
      default: return category;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'under_review': return 'Under Review';
      case 'resolved': return 'Resolved';
      case 'dismissed': return 'Dismissed';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'under_review': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'dismissed': return Colors.red;
      default: return Colors.grey;
    }
  }



  String _getIssueTypeDisplayName(String issueType) {
    switch (issueType) {
      case 'unsafe': return 'Unsafe';
      case 'harassment': return 'Harassment';
      case 'misleading': return 'Misleading';
      case 'inappropriate_behavior': return 'Inappropriate Behavior';
      case 'fraud': return 'Fraud';
      case 'spam': return 'Spam';
      case 'payment_issue': return 'Payment Issue';
      case 'safety_concern': return 'Safety Concern';
      case 'poor_quality': return 'Poor Quality';
      case 'no_show': return 'No Show';
      case 'other': return 'Other';
      default: return issueType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper methods for the new design
  String _getReporterInitial(String name) {
    if (name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  Color _getReporterColor(String name) {
    final colors = [
      const Color(0xFFE74C3C), // Red
      const Color(0xFF3498DB), // Blue  
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF1ABC9C), // Teal
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'user_issue': return const Color(0xFFE74C3C); // Red
      case 'technical_issue': return const Color(0xFF3498DB); // Blue
      case 'feature_suggestion': return const Color(0xFF2ECC71); // Green
      case 'service_category_request': return const Color(0xFFF39C12); // Orange
      case 'other': return const Color(0xFF95A5A6); // Gray
      default: return const Color(0xFF95A5A6);
    }
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF39C12); // Orange
      case 'under_review': return const Color(0xFF3498DB); // Blue
      case 'resolved': return const Color(0xFF2ECC71); // Green
      case 'dismissed': return const Color(0xFF95A5A6); // Gray
      case 'investigating': return const Color(0xFF9B59B6); // Purple
      default: return const Color(0xFF95A5A6);
    }
  }



  Widget _buildAuthenticationPrompt(AuthService authService) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Authentication Required',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in as an administrator to access reports',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Debug info in development mode
            if (kDebugMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    Text('• Authenticated: ${authService.isAuthenticated}'),
                    Text('• Is Admin: ${authService.isAdmin}'),
                    Text('• User Role: ${authService.userRole ?? 'None'}'),
                    Text('• Has Token: ${authService.token != null}'),
                    Text('• API Base URL: ${ApiConfig.currentApiBaseUrl}'),
                    Text('• Is Web: $kIsWeb'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _debugLoginAsAdmin(authService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Debug: Login as Admin'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _debugTestAPI(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Debug: Test API'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton(
              onPressed: () {
                // Navigate to login page or show login dialog
                Navigator.of(context).pushNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _debugLoginAsAdmin(AuthService authService) async {
    if (!kDebugMode) return;
    
    try {
      if (kDebugMode) {
        print('🔄 Debug: Attempting admin login...');
      }
      
      final response = await authService.login(
        email: 'roro@palhands.com',
        password: 'admin123',
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          print('✅ Debug: Admin login successful');
        }
        AppToast.show(context, message: 'Admin login successful!', type: AppToastType.success);
        // Reload reports after successful login
        _checkAuthAndLoadReports();
      } else {
        if (kDebugMode) {
          print('❌ Debug: Login failed - ${response['message']}');
        }
        AppToast.show(context, message: 'Login failed: ${response['message']}', type: AppToastType.error);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Debug: Login error - $e');
      }
      AppToast.show(context, message: 'Login error: $e', type: AppToastType.error);
    }
  }

  void _debugTestAPI() async {
    if (!kDebugMode) return;
    
    try {
      if (kDebugMode) {
        print('🔧 Debug: Testing API configuration...');
        print('🔧 Base URL: ${ApiConfig.currentBaseUrl}');
        print('🔧 API Base URL: ${ApiConfig.currentApiBaseUrl}');
        print('🔧 Is Web: $kIsWeb');
        print('🔧 Reports URL: ${ApiConfig.currentApiBaseUrl}/admin/reports');
      }
      
      AppToast.show(context, message: 'Check console for API debug info', type: AppToastType.info);
      
      // Try to load reports with debug info
      _checkAuthAndLoadReports();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Debug: API test error - $e');
      }
      AppToast.show(context, message: 'API test error: $e', type: AppToastType.error);
    }
  }
} 