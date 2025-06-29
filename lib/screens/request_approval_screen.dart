import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/role_guard.dart';

class RequestApprovalScreen extends StatefulWidget {
  const RequestApprovalScreen({super.key});

  @override
  State<RequestApprovalScreen> createState() => _RequestApprovalScreenState();
}

class _RequestApprovalScreenState extends State<RequestApprovalScreen> {
  final RequestService _requestService = RequestService();
  List<RequestModel> _requests = [];
  List<RequestModel> _filteredRequests = [];
  bool _isLoading = true;
  RequestType? _filterType;
  RequestStatus _filterStatus = RequestStatus.pending;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _requestService.getAllPendingRequests();
      setState(() {
        _requests = requests;
        _filteredRequests = requests;
        _isLoading = false;
      });
      _filterRequests();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _requests.where((request) {
        final matchesType = _filterType == null || request.type == _filterType;
        final matchesStatus = request.status == _filterStatus;
        return matchesType && matchesStatus;
      }).toList();
    });
  }

  Future<void> _approveRequest(RequestModel request) async {
    await _showApprovalDialog(request, RequestStatus.approved);
  }

  Future<void> _rejectRequest(RequestModel request) async {
    await _showApprovalDialog(request, RequestStatus.rejected);
  }

  Future<void> _showApprovalDialog(RequestModel request, RequestStatus newStatus) async {
    final TextEditingController notesController = TextEditingController();
    final bool isApproval = newStatus == RequestStatus.approved;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${isApproval ? 'Approve' : 'Reject'} Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request: ${request.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Type: ${request.typeText}'),
              if (request.amount != null) 
                Text('Amount: \$${request.amount!.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: isApproval ? 'Approval Notes (Optional)' : 'Rejection Reason',
                  hintText: isApproval 
                      ? 'Add any notes for this approval...' 
                      : 'Please provide a reason for rejection...',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproval ? const Color(0xFF27AE60) : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isApproval ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateRequestStatus(request, newStatus, notesController.text.trim());
    }
  }

  Future<void> _updateRequestStatus(RequestModel request, RequestStatus status, String notes) async {
    try {
      await _requestService.updateRequestStatus(
        requestId: request.id,
        status: status,
        approverNotes: notes.isNotEmpty ? notes : null,
      );

      // Remove from current list if it's no longer pending
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      _filterRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status.toString().split('.').last}'),
            backgroundColor: status == RequestStatus.approved 
                ? const Color(0xFF27AE60) 
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      permission: 'approve_requests',
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: const CustomAppBar(
          title: 'Request Approvals',
          showBackButton: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Type Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter by type:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<RequestType?>(
                              value: _filterType,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('All types'),
                              items: [
                                const DropdownMenuItem<RequestType?>(
                                  value: null,
                                  child: Text('All types'),
                                ),
                                ...RequestType.values.map((type) {
                                  return DropdownMenuItem<RequestType?>(
                                    value: type,
                                    child: Text(type.toString().split('.').last),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filterType = value;
                                });
                                _filterRequests();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<RequestStatus>(
                              value: _filterStatus,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: RequestStatus.values.map((status) {
                                return DropdownMenuItem<RequestStatus>(
                                  value: status,
                                  child: Text(status.toString().split('.').last),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _filterStatus = value;
                                  });
                                  _filterRequests();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Requests List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      )
                    : _filteredRequests.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundGray,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inbox_outlined,
                                      size: 48,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No pending requests',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'All caught up! No requests awaiting approval.',
                                    style: AppTheme.bodyText,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = _filteredRequests[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildRequestCard(request),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    Color typeColor;
    IconData typeIcon;

    switch (request.type) {
      case RequestType.goods:
        typeColor = const Color(0xFF27AE60);
        typeIcon = Icons.shopping_cart_outlined;
        break;
      case RequestType.cash:
        typeColor = AppTheme.primaryBlue;
        typeIcon = Icons.attach_money;
        break;
      case RequestType.leave:
        typeColor = const Color(0xFF9B59B6);
        typeIcon = Icons.time_to_leave_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, size: 20, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    Text(
                      request.typeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request.formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: AppTheme.bodyTextSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.amount != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Amount: \$${request.amount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectRequest(request),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}