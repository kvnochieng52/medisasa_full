import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileStatusWidget extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback? onProfileTap;

  const ProfileStatusWidget({
    Key? key,
    required this.userProfile,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's first login
    bool isFirstLogin = userProfile['first_login'] == 1;

    // Check if it's a specialist (account_type == 2) and not approved
    bool isSpecialistPendingApproval =
        userProfile['account_type'] == 2 && userProfile['sp_approved'] == 0;

    // Check if it's a specialist (account_type == 2) and approved
    bool isSpecialistApproved =
        userProfile['account_type'] == 2 && userProfile['sp_approved'] == 1;

    // Check if it's a service provider who hasn't paid subscription
    // We'll check if account_type is 2 (service provider) and subscription_paid is 0 or null
    bool isServiceProviderUnpaid = userProfile['account_type'] == 2 &&
        (userProfile['subscription_paid'] == null || userProfile['subscription_paid'] == 0);

    // Don't show widget if none of the conditions are met
    if (!isFirstLogin &&
        !isSpecialistPendingApproval &&
        !isSpecialistApproved &&
        !isServiceProviderUnpaid) {
      return const SizedBox.shrink();
    }

    // Determine colors and content based on status
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;
    String message;
    bool showPaymentButton = false;

    if (isServiceProviderUnpaid) {
      // Priority 1: Service provider needs to pay subscription
      backgroundColor = Colors.purple.shade50;
      borderColor = Colors.purple.shade200;
      iconColor = Colors.purple.shade600;
      textColor = Colors.purple.shade800;
      icon = Icons.star_outline_rounded;
      message = 'Activate Premium Account';
      showPaymentButton = true;
    } else if (isFirstLogin) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      iconColor = Colors.orange.shade600;
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
      message = 'Please finish your profile';
    } else if (isSpecialistApproved) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      iconColor = Colors.green.shade600;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle_rounded;
      message = '✓ Profile Approved';
    } else {
      // isSpecialistPendingApproval
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      iconColor = Colors.blue.shade600;
      textColor = Colors.blue.shade800;
      icon = Icons.pending_rounded;
      message = 'Profile Pending Approval';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showPaymentButton) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/subscription-payment');
                },
                icon: const Icon(Icons.rocket_launch, size: 14),
                label: const Text(
                  'Activate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ] else if (isFirstLogin && onProfileTap != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onProfileTap,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
