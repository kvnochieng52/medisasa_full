import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Singleton holding the current user's subscription state.
/// Populated by DashboardPage after every profile fetch.
class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  dynamic _accountType; // int or String
  Map<String, dynamic>? _subscriptionInfo;

  void update({dynamic accountType, Map<String, dynamic>? subscription}) {
    _accountType = accountType;
    _subscriptionInfo = subscription;
  }

  bool get isServiceProvider =>
      _accountType == 2 || _accountType?.toString() == '2';

  bool get hasActiveSubscription =>
      _subscriptionInfo != null && _subscriptionInfo!['status'] == 'paid';

  String? get planName => _subscriptionInfo?['plan_name'] as String?;
  String? get planSlug => _subscriptionInfo?['plan'] as String?;

  int? get maxFacilities => _limit('max_facilities');
  int? get maxHospitals => _limit('max_hospitals');
  int? get maxAppointmentsPerMonth => _limit('max_appointments_per_month');

  int? _limit(String key) {
    final limits = _subscriptionInfo?['limits'] as Map<String, dynamic>?;
    final val = limits?[key];
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }
}

/// Wraps [child] with a subscription gate for service providers.
/// - Admins and regular users are always allowed through.
/// - SPs with an active subscription are allowed through.
/// - SPs without a subscription see a full-page subscribe prompt.
class SubscriptionGate extends StatelessWidget {
  final Widget child;
  final String featureName;

  const SubscriptionGate({
    Key? key,
    required this.child,
    this.featureName = 'this feature',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = SubscriptionManager();
    if (!m.isServiceProvider || m.hasActiveSubscription) return child;
    return _GatePage(featureName: featureName);
  }
}

// ---------------------------------------------------------------------------
// Full-page prompt (used when SubscriptionGate blocks a page)
// ---------------------------------------------------------------------------
class _GatePage extends StatelessWidget {
  final String featureName;
  const _GatePage({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black87,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Subscription Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Access to $featureName requires an active subscription. '
                'Choose a plan to unlock this and other professional features.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _FeatureList(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/subscription-payment'),
                  icon: const Icon(Icons.star_rounded, size: 20),
                  label: const Text(
                    'View Subscription Plans',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  static const _items = [
    ('Receive Patient Appointments', Icons.calendar_today_rounded),
    ('Manage Facilities & Hospitals', Icons.business_rounded),
    ('Pharmacy & Products Management', Icons.local_pharmacy_rounded),
    ('Create Support Groups', Icons.people_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you get with a subscription:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$2,
                        size: 16, color: const Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.$1,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom-sheet prompt (used when gating drawer taps)
// ---------------------------------------------------------------------------

/// Call this in an onTap handler before navigating to a gated feature.
/// Closes [drawer] context first (if provided), shows a subscribe sheet,
/// and returns true when access is blocked so the caller can `return` early.
bool requiresSubscription(
  BuildContext context, {
  required String featureName,
}) {
  final m = SubscriptionManager();
  if (!m.isServiceProvider || m.hasActiveSubscription) return false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubscribeSheet(featureName: featureName),
  );
  return true;
}

class _SubscribeSheet extends StatelessWidget {
  final String featureName;
  const _SubscribeSheet({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 32, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Subscription Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need an active subscription to access $featureName.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/subscription-payment');
              },
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text(
                'View Plans & Subscribe',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}
