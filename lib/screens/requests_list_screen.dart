import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestService requestService = RequestService();

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: const CustomAppBar(title: 'My Requests'),
      body: SafeArea(
        child: StreamBuilder<List<RequestModel>>(
          stream: requestService.getUserRequestsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your internet connection',
                          style: AppTheme.bodyText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          'No requests found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You haven\'t submitted any requests yet',
                          style: AppTheme.bodyText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRequestCard(request),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.pending:
        statusColor = const Color(0xFFE67E22);
        statusIcon = Icons.pending;
        break;
      case RequestStatus.approved:
        statusColor = const Color(0xFF27AE60);
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
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
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      request.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.typeText,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: AppTheme.bodyTextSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.amount != null) ...[
            const SizedBox(height: 8),
            Text(
              'Amount: \$${request.amount!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                request.formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}