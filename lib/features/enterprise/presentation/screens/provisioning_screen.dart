import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../core/utils/logger.dart';
import '../../services/audit_log_service.dart';

// ── Provisioning config model ────────────────────────────────────────────────

/// Configuration payload fetched from an MDM provisioning URL.
class ProvisioningConfig {
  final String organizationName;
  final String? logoUrl;
  final String emailAddress;
  final String password;
  final String? mailServer;
  final int? mailPort;
  final String? sendServer;
  final int? sendPort;
  final String? itSupportUrl;

  const ProvisioningConfig({
    required this.organizationName,
    this.logoUrl,
    required this.emailAddress,
    required this.password,
    this.mailServer,
    this.mailPort,
    this.sendServer,
    this.sendPort,
    this.itSupportUrl,
  });

  factory ProvisioningConfig.fromJson(Map<String, dynamic> json) =>
      ProvisioningConfig(
        organizationName:
            (json['organization_name'] as String?) ?? 'Your Organization',
        logoUrl: json['logo_url'] as String?,
        emailAddress: json['email'] as String,
        password: json['password'] as String,
        mailServer: json['mail_server'] as String?,
        mailPort: json['mail_port'] as int?,
        sendServer: json['send_server'] as String?,
        sendPort: json['send_port'] as int?,
        itSupportUrl: json['it_support_url'] as String?,
      );
}

// ── Screen state ─────────────────────────────────────────────────────────────

enum _ProvisioningStatus {
  fetching,
  configuring,
  success,
  error,
}

// ── Screen ──────────────────────────────────────────────────────────────────

/// QR provisioning screen for enterprise enrollment.
///
/// Displayed on first launch when MDM has pushed a `provisioning_url` config.
/// Automatically fetches the provisioning configuration from the URL, then
/// calls [DeltaRpcClient.configureAccount] to set up the account. On success
/// navigates to the chat list. On error offers "Try Again" and "Manual Setup".
class ProvisioningScreen extends ConsumerStatefulWidget {
  /// The provisioning URL pushed by the MDM policy.
  final String provisioningUrl;

  const ProvisioningScreen({
    super.key,
    required this.provisioningUrl,
  });

  @override
  ConsumerState<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends ConsumerState<ProvisioningScreen>
    with SingleTickerProviderStateMixin {
  _ProvisioningStatus _status = _ProvisioningStatus.fetching;
  ProvisioningConfig? _config;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startProvisioning();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Provisioning flow ─────────────────────────────────────────────────────

  Future<void> _startProvisioning() async {
    setState(() {
      _status = _ProvisioningStatus.fetching;
      _errorMessage = null;
    });

    ProvisioningConfig config;
    try {
      config = await _fetchConfig(widget.provisioningUrl);
      _config = config;
    } catch (e) {
      AppLogger.e('ProvisioningScreen: fetch failed', e);
      setState(() {
        _status = _ProvisioningStatus.error;
        _errorMessage = 'Could not load provisioning configuration.\n$e';
      });
      return;
    }

    setState(() => _status = _ProvisioningStatus.configuring);

    try {
      await _configureAccount(config);
      await AuditLogService.instance.log(
        AuditEventType.accountAdded,
        metadata: {
          'method': 'provisioning_url',
          'org': config.organizationName,
          'email': config.emailAddress,
        },
      );
      setState(() => _status = _ProvisioningStatus.success);

      // Brief pause so the user sees the success state before navigating.
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        context.go(RouteConstants.chatList);
      }
    } catch (e) {
      AppLogger.e('ProvisioningScreen: configure failed', e);
      setState(() {
        _status = _ProvisioningStatus.error;
        _errorMessage = 'Account configuration failed.\n$e';
      });
    }
  }

  Future<ProvisioningConfig> _fetchConfig(String url) async {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));
    final response = await dio.get<dynamic>(url);

    Map<String, dynamic> data;
    if (response.data is Map) {
      data = Map<String, dynamic>.from(response.data as Map);
    } else if (response.data is String) {
      data = jsonDecode(response.data as String) as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format from provisioning URL.');
    }

    return ProvisioningConfig.fromJson(data);
  }

  Future<void> _configureAccount(ProvisioningConfig config) async {
    final client = ref.read(deltaRpcClientProvider);

    // Validate QR / provisioning URL via DeltaChat RPC (optional pre-check)
    final qrCheck = await client.checkQr(qr: widget.provisioningUrl);
    AppLogger.d('ProvisioningScreen.checkQr: $qrCheck');

    // Add a fresh account slot
    final accountId = await client.addAccount();

    // Configure with credentials from the provisioning payload
    await client.configureAccount(
      accountId: accountId,
      addr: config.emailAddress,
      password: config.password,
      mailServer: config.mailServer,
      mailPort: config.mailPort,
      sendServer: config.sendServer,
      sendPort: config.sendPort,
    );

    await client.selectAccount(accountId);
    await client.startIo(accountId);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent accidental back navigation during provisioning
      canPop: _status == _ProvisioningStatus.error ||
          _status == _ProvisioningStatus.success,
      child: Scaffold(
        backgroundColor: OmegaColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ProvisioningStatus.fetching:
        return _ProgressView(
          animation: _pulseAnimation,
          title: 'Connecting to your organization...',
          subtitle: 'Fetching your account configuration.',
          config: _config,
        );
      case _ProvisioningStatus.configuring:
        return _ProgressView(
          animation: _pulseAnimation,
          title: 'Configuring your account...',
          subtitle: _config != null
              ? 'Setting up ${_config!.emailAddress} for ${_config!.organizationName}.'
              : 'Please wait while your account is being prepared.',
          config: _config,
        );
      case _ProvisioningStatus.success:
        return _SuccessView(config: _config!);
      case _ProvisioningStatus.error:
        return _ErrorView(
          message: _errorMessage ?? 'An unexpected error occurred.',
          onRetry: _startProvisioning,
          onManualSetup: () => context.go(RouteConstants.onboarding),
        );
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _OrgLogo extends StatelessWidget {
  final String? logoUrl;
  const _OrgLogo({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: OmegaColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.business_rounded,
          size: 44,
          color: OmegaColors.primary,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        logoUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: OmegaColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_rounded,
            size: 44,
            color: OmegaColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String subtitle;
  final ProvisioningConfig? config;

  const _ProgressView({
    required this.animation,
    required this.title,
    required this.subtitle,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        ScaleTransition(
          scale: animation,
          child: _OrgLogo(logoUrl: config?.logoUrl),
        ),
        const SizedBox(height: 24),
        if (config != null) ...[
          Text(
            config!.organizationName,
            style: OmegaTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: OmegaTextStyles.titleMedium.copyWith(
            color: OmegaColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: OmegaTextStyles.bodyMedium.copyWith(
            color: OmegaColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        const SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            color: OmegaColors.primary,
            strokeWidth: 3,
          ),
        ),
        const Spacer(flex: 3),
        _OmegaBadge(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final ProvisioningConfig config;
  const _SuccessView({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        _OrgLogo(logoUrl: config.logoUrl),
        const SizedBox(height: 24),
        Text(
          config.organizationName,
          style: OmegaTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Icon(
          Icons.check_circle_rounded,
          color: OmegaColors.success,
          size: 52,
        ),
        const SizedBox(height: 12),
        Text(
          'Account configured!',
          style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.success),
        ),
        const SizedBox(height: 8),
        Text(
          config.emailAddress,
          style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Taking you to your inbox...',
          style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textDisabled),
        ),
        const Spacer(flex: 3),
        _OmegaBadge(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onManualSetup;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onManualSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: OmegaColors.error.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: OmegaColors.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Setup failed',
          style: OmegaTextStyles.titleLarge.copyWith(color: OmegaColors.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: OmegaTextStyles.bodyMedium.copyWith(
            color: OmegaColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 2),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text('Try Again', style: OmegaTextStyles.labelLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: OmegaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onManualSetup,
            icon: const Icon(Icons.settings_rounded, size: 20),
            label: Text('Manual Setup', style: OmegaTextStyles.labelLarge),
            style: OutlinedButton.styleFrom(
              foregroundColor: OmegaColors.textSecondary,
              side: const BorderSide(color: OmegaColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _OmegaBadge(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OmegaBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_rounded, size: 16, color: OmegaColors.primary),
        const SizedBox(width: 6),
        Text(
          'Secured by Omega',
          style: OmegaTextStyles.labelSmall.copyWith(
            color: OmegaColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
