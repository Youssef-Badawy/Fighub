import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';
import 'verification_model.dart';
import 'verification_service.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
  });

  @override
  State<VerificationPage> createState() =>
      _VerificationPageState();
}

class _VerificationPageState
    extends State<VerificationPage> {
  final VerificationService _verificationService =
      VerificationService();

  final CloudinaryService _cloudinaryService =
      CloudinaryService();

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedPlanId =
      VerificationPlan.monthly.id;

  XFile? _paymentProof;
  bool _isUploading = false;
  bool _isSubmitting = false;

  Future<void> _pickPaymentProof() async {
    if (_isUploading || _isSubmitting) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _paymentProof = image;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not select the payment proof: $error',
          ),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (_isUploading || _isSubmitting) {
      return;
    }

    final paymentProof = _paymentProof;

    if (paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a payment proof image first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isUploading = true;
    });

    try {
      final paymentProofUrl =
          await _cloudinaryService.uploadImage(
        paymentProof,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      await _verificationService.createRequest(
        planId: _selectedPlanId,
        paymentProofUrl: paymentProofUrl,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification request submitted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit the verification request: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Color _statusColor(
    BuildContext context,
    String status,
  ) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.orange;
      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  Widget _buildRequestStatus(
    BuildContext context,
    VerificationRequest request,
  ) {
    final statusColor =
        _statusColor(context, request.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Current verification request',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  request.isCurrentlyVerified
                      ? Icons.verified
                      : Icons.info_outline,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  request.isCurrentlyVerified
                      ? 'Verified'
                      : request.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Plan: ${request.planId == 'monthly' ? 'Monthly' : '3 Months'}',
            ),
            Text(
              'Amount: ${request.amount} EGP',
            ),
            Text(
              'Submitted: '
              '${_formatDate(request.createdAt)}',
            ),
            if (request.startsAt != null)
              Text(
                'Starts: '
                '${_formatDate(request.startsAt)}',
              ),
            if (request.expiresAt != null)
              Text(
                'Expires: '
                '${_formatDate(request.expiresAt)}',
              ),
            if (request.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${request.rejectionReason}',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
            if (request.isCurrentlyVerified) ...[
              const SizedBox(height: 12),
              const Text(
                'Your verification is currently active.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    VerificationPlan plan,
  ) {
    final selected =
        _selectedPlanId == plan.id;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: RadioGroup<String>(
        groupValue: _selectedPlanId,
        onChanged: (value) {
          if (_isSubmitting || value == null) {
            return;
          }

          setState(() {
            _selectedPlanId = value;
          });
        },
        child: RadioListTile<String>(
          value: plan.id,
          title: Text(
            plan.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${plan.price} EGP • '
            '${plan.durationMonths} '
            '${plan.durationMonths == 1 ? 'month' : 'months'}',
          ),
          secondary: Icon(
            selected
                ? Icons.verified
                : Icons.verified_outlined,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: StreamBuilder<VerificationRequest?>(
        stream:
            _verificationService.watchMyLatestRequest(),
        builder: (context, snapshot) {
          final request = snapshot.data;

          final hasPendingRequest =
              request?.isPending ?? false;

          final hasActiveVerification =
              request?.isCurrentlyVerified ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Become a verified seller',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Choose a verification plan and '
                        'submit your payment proof. '
                        'Your request will be reviewed before '
                        'verification is activated.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (request != null) ...[
                _buildRequestStatus(
                  context,
                  request,
                ),
                const SizedBox(height: 16),
              ],

              if (hasActiveVerification)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.verified,
                    ),
                    title: const Text(
                      'Verification is active',
                    ),
                    subtitle: Text(
                      'Expires on '
                      '${_formatDate(request?.expiresAt)}',
                    ),
                  ),
                ),

              if (!hasPendingRequest &&
                  !hasActiveVerification) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment information',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'After choosing your plan, transfer '
                          'the exact amount to one of the wallets below, '
                          'then upload your payment proof.',
                        ),
                        const SizedBox(height: 12),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          title: Text('Orange Cash'),
                          subtitle: Text('01271882120'),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          title: Text('Vodafone Cash'),
                          subtitle: Text('01012446579'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Choose your plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                ...VerificationPlan.all.map(
                  (plan) => _buildPlanCard(
                    context,
                    plan,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Payment proof',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _pickPaymentProof,
                  icon: const Icon(
                    Icons.photo_library_outlined,
                  ),
                  label: Text(
                    _paymentProof == null
                        ? 'Choose payment proof'
                        : 'Change payment proof',
                  ),
                ),

                if (_paymentProof != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.image_outlined,
                      ),
                      title: Text(
                        _paymentProof!.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      subtitle: const Text(
                        'Payment proof selected',
                      ),
                      trailing: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _paymentProof = null;
                                });
                              },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed:
                      _isSubmitting || _paymentProof == null
                          ? null
                          : _submitRequest,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                        ),
                  label: Text(
                    _isUploading
                        ? 'Uploading payment proof...'
                        : _isSubmitting
                            ? 'Submitting...'
                            : 'Submit verification request',
                  ),
                ),
              ] else if (hasPendingRequest) ...[
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Text(
                      'Your verification request is '
                      'currently pending review.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
