import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/custom_service_request_service.dart';
import '../services/auth_service.dart';

class CustomServiceRequestsWidget extends StatefulWidget {
  final bool isAdmin;

  const CustomServiceRequestsWidget({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<CustomServiceRequestsWidget> createState() => _CustomServiceRequestsWidgetState();
}

class _CustomServiceRequestsWidgetState extends State<CustomServiceRequestsWidget> {
  final _customRequestService = CustomServiceRequestService();
  final _authService = AuthService();

  List<CustomServiceRequest> _requests = [];
  bool _isLoading = false;
  String _statusMessage = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (widget.isAdmin) {
        _requests = await _customRequestService.getAllCustomServiceRequests(
          status: _selectedStatus == 'all' ? null : _selectedStatus,
        );
      } else {
        _requests = await _customRequestService.getMyCustomServiceRequests();
      }

      setState(() {
        _statusMessage = 'Loaded ${_requests.length} requests';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading requests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(CustomServiceRequest request) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _customRequestService.approveCustomServiceRequest(
        request.id,
        approvedTitle: request.title,
        approvedDescription: request.description,
        approvedPrice: request.proposedPrice,
        approvedCategory: request.category,
        notes: 'Approved by admin',
      );

      if (success) {
        setState(() {
          _statusMessage = 'Request approved successfully!';
        });
        await _loadRequests(); // Refresh the list
      } else {
        setState(() {
          _statusMessage = 'Failed to approve request';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error approving request: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectRequest(CustomServiceRequest request) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejecting this request:'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            child: Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );

    if (reason != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _customRequestService.rejectCustomServiceRequest(
          request.id,
          reason: reason,
        );

        if (success) {
          setState(() {
            _statusMessage = 'Request rejected successfully!';
          });
          await _loadRequests(); // Refresh the list
        } else {
          setState(() {
            _statusMessage = 'Failed to reject request';
          });
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'Error rejecting request: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.isAdmin ? 'Custom Service Requests' : 'My Custom Service Requests',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.isAdmin) ...[
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _loadRequests();
                    }
                  },
                ),
                SizedBox(width: 12.w),
              ],
              IconButton(
                onPressed: _loadRequests,
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Status Message
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          SizedBox(height: 16.h),

          // Requests List
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16.h),
                  Text('Loading requests...'),
                ],
              ),
            )
          else if (_requests.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64.sp,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No custom service requests found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  return _buildRequestCard(request);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CustomServiceRequest request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getStatusColor(request.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Category: ${request.category}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                request.statusDisplay,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            Text(
              'Price: ${request.currency} ${request.proposedPrice}/hour',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (request.location != null) ...[
              SizedBox(height: 4.h),
              Text(
                'Location: ${request.location}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 4.h),
            Text(
              'Provider: ${request.providerName}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Submitted: ${request.createdAt.toString().substring(0, 16)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  request.description,
                  style: TextStyle(fontSize: 14.sp),
                ),
                
                SizedBox(height: 16.h),

                // Additional Details
                if (request.additionalDetails != null) ...[
                  Text(
                    'Additional Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    request.additionalDetails!,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Requirements
                if (request.requirements.isNotEmpty) ...[
                  Text(
                    'Requirements:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ...request.requirements.map((req) => Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16.sp, color: AppColors.success),
                        SizedBox(width: 8.w),
                        Expanded(child: Text(req, style: TextStyle(fontSize: 14.sp))),
                      ],
                    ),
                  )),
                  SizedBox(height: 16.h),
                ],

                // Equipment
                if (request.equipment.isNotEmpty) ...[
                  Text(
                    'Equipment:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ...request.equipment.map((eq) => Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Row(
                      children: [
                        Icon(Icons.build, size: 16.sp, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Expanded(child: Text(eq, style: TextStyle(fontSize: 14.sp))),
                      ],
                    ),
                  )),
                  SizedBox(height: 16.h),
                ],

                // Admin Notes (if approved/rejected)
                if (request.notes != null) ...[
                  Text(
                    'Admin Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    request.notes!,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Rejection Reason
                if (request.rejectionReason != null) ...[
                  Text(
                    'Rejection Reason:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    request.rejectionReason!,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.error),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Admin Actions
                if (widget.isAdmin && request.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveRequest(request),
                          icon: Icon(Icons.check, size: 16.sp),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectRequest(request),
                          icon: Icon(Icons.close, size: 16.sp),
                          label: Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
