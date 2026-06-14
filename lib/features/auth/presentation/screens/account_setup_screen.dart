import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';

enum _SetupStep { email, password, serverConfig, displayName, done }

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  _SetupStep _step = _SetupStep.email;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  bool _showAdvanced = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _advance() {
    setState(() {
      _step = _SetupStep.values[_step.index + 1];
    });
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (mounted) context.go(RouteConstants.chatList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: _step.index > 0
            ? BackButton(onPressed: () => setState(() => _step = _SetupStep.values[_step.index - 1]))
            : BackButton(onPressed: () => context.go(RouteConstants.welcome)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _StepIndicator(step: _step),
              const SizedBox(height: 32),
              Expanded(child: _stepContent),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _SetupStep.email: return 'Your Email';
      case _SetupStep.password: return 'Password';
      case _SetupStep.serverConfig: return 'Server Settings';
      case _SetupStep.displayName: return 'Your Name';
      case _SetupStep.done: return 'All Set!';
    }
  }

  Widget get _stepContent {
    switch (_step) {
      case _SetupStep.email:
        return _EmailStep(
          controller: _emailController,
          onNext: _advance,
        );
      case _SetupStep.password:
        return _PasswordStep(
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          showAdvanced: _showAdvanced,
          onToggleAdvanced: () => setState(() => _showAdvanced = !_showAdvanced),
          serverController: _serverController,
          portController: _portController,
          onNext: _advance,
        );
      case _SetupStep.serverConfig:
        return _ServerConfigStep(onNext: _advance);
      case _SetupStep.displayName:
        return _DisplayNameStep(
          controller: _displayNameController,
          onComplete: _complete,
          loading: _loading,
        );
      case _SetupStep.done:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final _SetupStep step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final total = _SetupStep.values.length - 1;
    final current = step.index;
    return LinearProgressIndicator(
      value: current / total,
      backgroundColor: OmegaColors.divider,
      valueColor: const AlwaysStoppedAnimation(OmegaColors.primary),
      borderRadius: BorderRadius.circular(2),
    );
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _EmailStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your email address', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => onNext(),
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            hintText: 'you@example.com',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue'),
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            'Omega works with any existing email account.\nNo new account needed.',
            style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool showAdvanced;
  final VoidCallback onToggleAdvanced;
  final TextEditingController serverController;
  final TextEditingController portController;
  final VoidCallback onNext;

  const _PasswordStep({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.showAdvanced,
    required this.onToggleAdvanced,
    required this.serverController,
    required this.portController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your email password', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onNext(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onToggleAdvanced,
          icon: Icon(showAdvanced ? Icons.expand_less : Icons.expand_more, size: 18),
          label: const Text('Advanced (IMAP/SMTP)'),
        ),
        if (showAdvanced) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: serverController,
            decoration: const InputDecoration(
              labelText: 'IMAP Server',
              hintText: 'imap.example.com',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'IMAP Port',
              hintText: '993',
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _ServerConfigStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ServerConfigStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sync_rounded, size: 64, color: OmegaColors.primary),
        const SizedBox(height: 24),
        Text('Configuring server...', style: OmegaTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Omega is detecting optimal server settings',
          style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const LinearProgressIndicator(),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _DisplayNameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onComplete;
  final bool loading;

  const _DisplayNameStep({
    required this.controller,
    required this.onComplete,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How should people see you?', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onComplete(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
            prefixIcon: Icon(Icons.person_outline_rounded),
            hintText: 'Your Name',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onComplete,
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Finish Setup'),
          ),
        ),
      ],
    );
  }
}
