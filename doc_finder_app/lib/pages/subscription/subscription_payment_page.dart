import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xyvra_health/app_router.dart';
import 'package:xyvra_health/services/payment_deep_link_service.dart';
import 'package:xyvra_health/services/subscription_service.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  final String? currentPlanSlug;

  const SubscriptionPaymentPage({Key? key, this.currentPlanSlug})
      : super(key: key);

  @override
  _SubscriptionPaymentPageState createState() =>
      _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  String? selectedPlanSlug;
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Map<String, dynamic>> _packages = [];
  bool _loadingPackages = true;
  bool _isProcessing = false;

  final List<Color> _planColors = [Colors.blue, Colors.green, Colors.purple];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await _subscriptionService.getSubscriptionPlans();
    if (mounted) {
      // Filter out the current plan so users can only upgrade
      final filtered = widget.currentPlanSlug != null
          ? packages.where((p) => p['slug'] != widget.currentPlanSlug).toList()
          : packages;
      setState(() {
        _packages = filtered;
        if (filtered.isNotEmpty) {
          selectedPlanSlug = filtered.first['slug'] as String?;
        }
        _loadingPackages = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedPackage {
    if (selectedPlanSlug == null) return null;
    try {
      return _packages.firstWhere((p) => p['slug'] == selectedPlanSlug);
    } catch (_) {
      return null;
    }
  }

  Color _colorForIndex(int index) =>
      _planColors[index % _planColors.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Service Provider Subscription',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingPackages
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildSubscriptionPlans(),
                    const SizedBox(height: 30),
                    _buildProceedButton(),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Secured by DPO Pay',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final isUpgrade = widget.currentPlanSlug != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUpgrade ? 'Upgrade Your Plan' : 'Complete Your Registration',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isUpgrade
              ? 'Select a plan to upgrade your current subscription'
              : 'Choose a subscription plan to activate your service provider account',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Subscription Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._packages.asMap().entries.map((entry) {
          final index = entry.key;
          final pkg = entry.value;
          final slug = pkg['slug'] as String;
          final isSelected = selectedPlanSlug == slug;
          final planColor = _colorForIndex(index);
          final features = List<String>.from(pkg['features'] as List? ?? []);
          final isPopular = pkg['is_popular'] == true;
          final amount = double.tryParse(pkg['amount'].toString()) ?? 0;

          return GestureDetector(
            onTap: () => setState(() => selectedPlanSlug = slug),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? planColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: planColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  if (isPopular)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: planColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'MOST POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? planColor
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: planColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pkg['description'] as String? ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'KES ${amount == amount.truncateToDouble() ? amount.toInt() : amount}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? planColor : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (features.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[200], height: 1),
                          const SizedBox(height: 10),
                          ...features.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 15,
                                      color: isSelected
                                          ? planColor
                                          : Colors.grey[400]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProceedButton() {
    final pkg = _selectedPackage;
    final planIndex = _packages.indexWhere((p) => p['slug'] == selectedPlanSlug);
    final planColor = planIndex >= 0 ? _colorForIndex(planIndex) : Colors.blue;
    final bool canProceed = pkg != null && !_isProcessing;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canProceed ? _showPaymentConfirmation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? planColor : Colors.grey[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: canProceed ? 2 : 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Proceed to Payment',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  if (pkg != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(KES ${double.tryParse(pkg['amount'].toString())?.toInt() ?? 0})',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  void _showPaymentConfirmation() {
    final pkg = _selectedPackage;
    if (pkg == null) return;

    final planIndex = _packages.indexOf(pkg);
    final planColor = _colorForIndex(planIndex);
    final amount =
        double.tryParse(pkg['amount'].toString())?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: planColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment, color: planColor, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirm Payment',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You will be redirected to DPO Pay to complete your ${pkg['name']} subscription',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Plan', pkg['name'] as String),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total Amount',
                    'KES $amount',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processPayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: planColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.black87 : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _subscriptionService.processPayment(
        plan: selectedPlanSlug!,
        paymentMethod: 'dpo',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result['success'] as bool) {
        final data = result['data'] as Map<String, dynamic>;
        final paymentUrl = data['payment_url'] as String;
        final transToken = data['trans_token'] as String;

        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) _showPaymentPollingSheet(transToken);
        } else {
          _showError('Could not open payment page. Please try again.');
        }
      } else {
        _showError(result['message'] as String? ??
            'Failed to initiate payment');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('An error occurred. Please try again.');
      }
    }
  }

  void _showPaymentPollingSheet(String transToken) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentPollingSheet(
        transToken: transToken,
        subscriptionService: _subscriptionService,
        onSuccess: () {
          if (ctx.mounted) {
            try { Navigator.pop(ctx); } catch (_) {}
          }
          AppRouter.router.go('/payment-success');
        },
        onFailed: (message) {
          Navigator.pop(ctx);
          if (mounted) _showError(message);
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _PaymentPollingSheet extends StatefulWidget {
  final String transToken;
  final SubscriptionService subscriptionService;
  final VoidCallback onSuccess;
  final void Function(String message) onFailed;

  const _PaymentPollingSheet({
    required this.transToken,
    required this.subscriptionService,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  State<_PaymentPollingSheet> createState() => _PaymentPollingSheetState();
}

class _PaymentPollingSheetState extends State<_PaymentPollingSheet> {
  Timer? _timer;
  StreamSubscription<Uri>? _deepLinkSub;
  String _statusText = 'Waiting for payment confirmation...';
  bool _checking = false;
  int _pollCount = 0;
  static const int _maxPolls = 40; // 40 × 5s ≈ 3 min timeout

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());

    // When DPO redirects back to the app via deep link, handle immediately.
    // The backend already verified the payment before showing the result page,
    // so we trust the deep link path without re-polling the API.
    _deepLinkSub = PaymentDeepLinkService().stream.listen((uri) {
      if (!mounted) return;
      _timer?.cancel();
      // xyvrahealth:///payment/success → path=/payment/success (triple-slash, preferred)
      // xyvrahealth://payment/success  → host=payment, path=/success (legacy double-slash)
      final isSuccess = uri.path == '/payment/success' ||
          (uri.host == 'payment' && uri.path == '/success');
      final isFailed = uri.path == '/payment/failed' ||
          (uri.host == 'payment' && uri.path == '/failed');
      if (isSuccess) {
        widget.onSuccess();
      } else if (isFailed) {
        widget.onFailed('Payment failed. Please try again.');
      } else {
        widget.onFailed('Payment was cancelled.');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    _pollCount++;

    if (_pollCount > _maxPolls) {
      _timer?.cancel();
      setState(() => _statusText =
          'Payment timed out. Please check your subscription status in the app.');
      return;
    }

    setState(() {
      _checking = true;
      _statusText = 'Checking payment status...';
    });

    final result =
        await widget.subscriptionService.verifyPayment(widget.transToken);

    if (!mounted) return;

    final status = result['status'] as String? ?? 'pending';

    if (status == 'paid') {
      _timer?.cancel();
      widget.onSuccess();
      return;
    } else if (status == 'failed' || status == 'cancelled') {
      _timer?.cancel();
      widget.onFailed(
          result['message'] as String? ?? 'Payment $status. Please try again.');
      return;
    }

    setState(() {
      _checking = false;
      _statusText = 'Waiting for payment confirmation...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment In Progress',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _statusText,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete payment on the DPO Pay page that opened in your browser.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checking ? null : _checkStatus,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Check Payment Status',
                  style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
