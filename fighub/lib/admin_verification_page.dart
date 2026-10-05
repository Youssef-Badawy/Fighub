import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'verification_model.dart';
import 'verification_service.dart';

class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({
    super.key,
  });

  @override
  State<AdminVerificationPage> createState() =>
      _AdminVerificationPageState();
}

class _AdminVerificationPageState
    extends State<AdminVerificationPage> {
  final VerificationService _verificationService =
      VerificationService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isProcessing = false;

  Stream<List<VerificationRequest>> _watchRequests() {
    return _firestore
        .collection('verification_requests')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  VerificationRequest.fromFirestore,
                )
                .toList();
          },
        );
  }

  Future<Map<String, dynamic>?> _getUser(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return null;
    }

    final document = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    return document.data();
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

  Future<void> _approve(
    VerificationRequest request,
  ) async {
    if (request.id == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _verificationService.approveRequest(
        requestId: request.id!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification request approved.',
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
            'Could not approve request: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _reject(
    VerificationRequest request,
  ) async {
    if (request.id == null || _isProcessing) {
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject verification',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter the rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  controller.text.trim(),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _verificationService.rejectRequest(
        requestId: request.id!,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification request rejected.',
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
            'Could not reject request: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaymentProof(
    String url,
  ) {
    if (url.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Could not load payment proof.',
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    VerificationRequest request,
  ) {
    Color color;

    switch (request.status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      case 'Expired':
        color = Colors.orange;
        break;
      default:
        color =
            Theme.of(context).colorScheme.primary;
    }

    return Chip(
      avatar: Icon(
        request.status == 'Approved'
            ? Icons.verified
            : Icons.info_outline,
        size: 18,
        color: color,
      ),
      label: Text(request.status),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    VerificationRequest request,
  ) {
    final isPending = request.isPending;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUser(request.userId),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;

            final name =
                user?['name'] as String? ?? 'Unknown user';

            final email =
                user?['email'] as String? ?? '';

            final phone =
                user?['phone'] as String? ?? '';

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                    ),
                    _buildStatusChip(
                      context,
                      request,
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(email),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone),
                ],
                const SizedBox(height: 12),
                Text(
                  'Plan: '
                  '${request.planId == 'monthly' ? 'Monthly' : '3 Months'}',
                ),
                Text(
                  'Amount: ${request.amount} EGP',
                ),
                Text(
                  'Submitted: '
                  '${_formatDate(request.createdAt)}',
                ),
                if (request.expiresAt != null)
                  Text(
                    'Expires: '
                    '${_formatDate(request.expiresAt)}',
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: request.paymentProofUrl
                          .isEmpty
                      ? null
                      : () {
                          _showPaymentProof(
                            request.paymentProofUrl,
                          );
                        },
                  icon: const Icon(
                    Icons.image_outlined,
                  ),
                  label: const Text(
                    'View payment proof',
                  ),
                ),
                if (request.rejectionReason
                    .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rejection reason: '
                    '${request.rejectionReason}',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  _approve(
                                    request,
                                  );
                                },
                          icon: const Icon(
                            Icons.check,
                          ),
                          label: const Text(
                            'Approve',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  _reject(
                                    request,
                                  );
                                },
                          icon: const Icon(
                            Icons.close,
                          ),
                          label: const Text(
                            'Reject',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verification Requests',
        ),
      ),
      body: StreamBuilder<List<VerificationRequest>>(
        stream: _watchRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load verification requests.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests =
              snapshot.data ?? const [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No verification requests yet.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(
                context,
                requests[index],
              );
            },
          );
        },
      ),
    );
  }
}
