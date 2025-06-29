import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class RequestScreen extends StatefulWidget {
  final RequestType requestType;

  const RequestScreen({
    super.key,
    required this.requestType,
  });

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final RequestService _requestService = RequestService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      double? amount;
      if (widget.requestType == RequestType.cash && _amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }

      await _requestService.submitRequest(
        type: widget.requestType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _screenTitle {
    switch (widget.requestType) {
      case RequestType.goods:
        return 'Goods Request';
      case RequestType.cash:
        return 'Cash Request';
      case RequestType.leave:
        return 'Leave Request';
    }
  }

  String get _titleHint {
    switch (widget.requestType) {
      case RequestType.goods:
        return 'Office supplies, equipment, etc.';
      case RequestType.cash:
        return 'Daily expenses, travel allowance, etc.';
      case RequestType.leave:
        return 'Annual leave, sick leave, etc.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: CustomAppBar(title: _screenTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        label: 'Title',
                        hintText: _titleHint,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hintText: 'Provide detailed information about your request',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      if (widget.requestType == RequestType.cash) ...[
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hintText: 'Enter amount in currency',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Submit Request',
                  onPressed: _isLoading ? null : _submitRequest,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request will be reviewed by your supervisor. You will be notified once approved or rejected.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}