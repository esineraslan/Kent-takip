import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/auth_models.dart';
import 'package:kent_takip_app/src/auth/demo_auth_service.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/widgets/brand_header.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

final class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final _phoneController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: context.strings.signInDemo,
      description: context.strings.syntheticNotice,
      icon: Icons.phone_android_rounded,
      onBack: () {
        final router = GoRouter.of(context);
        context.read<AuthFlowController>().clear();
        router.go(AppPaths.citizenWelcome);
      },
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: InputDecoration(
                labelText: context.strings.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: context.strings.text('u0654'),
                errorText: _error,
              ),
              onSubmitted: (_) => unawaited(_submit()),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _phoneController.text = '+90 555 000 11 22';
                      _error = null;
                    }),
              child: Text(context.strings.demoAccountFill),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => unawaited(_submit()),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined),
              label: Text(context.strings.sendCode),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<DemoAuthService>();
      final phone = auth.normalizePhone(_phoneController.text);
      await auth.requestCitizenOtp(phone);
      if (!mounted) {
        return;
      }
      context.read<AuthFlowController>().beginCitizenVerification(phone);
      final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
      context.go(
        Uri(
          path: AppPaths.citizenVerify,
          queryParameters: returnTo == null ? null : {'returnTo': returnTo},
        ).toString(),
      );
    } on DemoAuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = _failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

final class CitizenVerifyScreen extends StatefulWidget {
  const CitizenVerifyScreen({super.key});

  @override
  State<CitizenVerifyScreen> createState() => _CitizenVerifyScreenState();
}

final class _CitizenVerifyScreenState extends State<CitizenVerifyScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthFlowController>().citizenPhone;
    if (phone == null) {
      return _MissingChallenge(
        message: context.strings.authRequired,
        target: AppPaths.citizenLogin,
      );
    }
    return _AuthScaffold(
      title: context.strings.verificationCode,
      description: context.localeFormat.maskedPhone(phone),
      icon: Icons.verified_user_outlined,
      onBack: () {
        final router = GoRouter.of(context);
        context.read<AuthFlowController>().clear();
        router.go(AppPaths.citizenLogin);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: context.strings.verificationCode,
              prefixIcon: const Icon(Icons.password_rounded),
              errorText: _error,
            ),
            onSubmitted: (_) => unawaited(_submit(phone)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_submit(phone)),
            child: Text(context.strings.verifyAndContinue),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String phone) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final principal = await context.read<DemoAuthService>().verifyCitizenOtp(
        phone,
        _codeController.text,
      );
      if (!mounted) {
        return;
      }
      final returnTo = const AppRoutePolicy().safeReturnTo(
        GoRouterState.of(context).uri.queryParameters['returnTo'],
      );
      final router = GoRouter.of(context);
      final session = context.read<SessionController>();
      final authFlow = context.read<AuthFlowController>();
      session.signIn(principal);
      authFlow.clear();
      router.go(returnTo ?? AppPaths.citizenMap);
    } on DemoAuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = _failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

final class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

final class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: context.strings.municipalOfficer,
      description: context.strings.syntheticNotice,
      icon: Icons.account_balance_outlined,
      onBack: () {
        final router = GoRouter.of(context);
        context.read<AuthFlowController>().clear();
        router.go(AppPaths.demoStart);
      },
      darkAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            decoration: InputDecoration(
              labelText: context.strings.staffEmail,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: context.strings.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? context.strings.text('u0563')
                    : context.strings.text('u0564'),
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              errorText: _error,
            ),
            onSubmitted: (_) => unawaited(_submit()),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _emailController.text = DemoAuthService.supervisorEmail;
                      _passwordController.text = DemoAuthService.supervisorPassword;
                      _error = null;
                    }),
              child: Text(context.strings.demoAccountFill),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => unawaited(_submit()),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(context.strings.continueAction),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await context.read<DemoAuthService>().verifyStaffPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      context.read<AuthFlowController>().beginStaffMfa(challenge);
      final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
      context.go(
        Uri(
          path: AppPaths.staffMfa,
          queryParameters: returnTo == null ? null : {'returnTo': returnTo},
        ).toString(),
      );
    } on DemoAuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = _failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

final class StaffMfaScreen extends StatefulWidget {
  const StaffMfaScreen({super.key});

  @override
  State<StaffMfaScreen> createState() => _StaffMfaScreenState();
}

final class _StaffMfaScreenState extends State<StaffMfaScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = context.watch<AuthFlowController>().staffChallenge;
    if (challenge == null) {
      return _MissingChallenge(
        message: context.strings.secondFactor,
        target: AppPaths.staffLogin,
      );
    }
    return _AuthScaffold(
      title: context.strings.secondFactor,
      description: DemoAuthService.supervisorEmail,
      icon: Icons.security_rounded,
      darkAccent: true,
      onBack: () {
        final router = GoRouter.of(context);
        context.read<AuthFlowController>().clear();
        router.go(AppPaths.staffLogin);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: context.strings.verificationCode,
              prefixIcon: const Icon(Icons.password_rounded),
              errorText: _error,
            ),
            onSubmitted: (_) => unawaited(_submit(challenge)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () => unawaited(_submit(challenge)),
            child: Text(context.strings.verifyAndContinue),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(StaffChallenge challenge) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final principal = await context.read<DemoAuthService>().verifyStaffMfa(
        challenge,
        _codeController.text,
      );
      if (!mounted) {
        return;
      }
      final returnTo = const AppRoutePolicy().safeReturnTo(
        GoRouterState.of(context).uri.queryParameters['returnTo'],
      );
      final router = GoRouter.of(context);
      final session = context.read<SessionController>();
      final authFlow = context.read<AuthFlowController>();
      session.signIn(principal);
      authFlow.clear();
      router.go(returnTo ?? AppPaths.staffDashboard);
    } on DemoAuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = _failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

String _failureMessage(BuildContext context, DemoAuthFailure failure) {
  final message = switch (failure.code) {
    DemoAuthFailureCode.invalidIdentity => context.strings.invalidIdentity,
    DemoAuthFailureCode.invalidCredential => context.strings.invalidCredential,
    DemoAuthFailureCode.lockedOut => context.strings.lockedOut,
    DemoAuthFailureCode.requestCooldown => context.strings.requestCooldown,
    DemoAuthFailureCode.expiredChallenge => context.strings.expiredChallenge,
  };
  final retryAt = failure.retryAt;
  if (retryAt == null) {
    return message;
  }
  final now = context.read<Clock>().nowUtc();
  final seconds = retryAt.difference(now).inSeconds.clamp(1, 60);
  return context.strings.format('u0656', {'message': message, 'seconds': seconds});
}

final class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.description,
    required this.icon,
    required this.onBack,
    required this.child,
    this.darkAccent = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onBack;
  final Widget child;
  final bool darkAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (wide)
                  Expanded(
                    flex: 5,
                    child: ColoredBox(
                      color: darkAccent
                          ? AppColors.brandBlue900
                          : AppColors.brandBlue050,
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BrandMark(onDark: darkAccent),
                            const Spacer(),
                            Icon(
                              icon,
                              size: 72,
                              color: darkAccent
                                  ? Colors.white
                                  : AppColors.brandBlue800,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              context.strings.tagline,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: darkAccent ? Colors.white : AppColors.textStrong,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  flex: wide ? 6 : 1,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 64 : 20,
                      vertical: 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: context.strings.back,
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                            if (!wide) ...[
                              const SizedBox(height: 8),
                              const BrandMark(compact: true),
                            ],
                            const SizedBox(height: 36),
                            Icon(icon, size: 44, color: AppColors.brandBlue800),
                            const SizedBox(height: 18),
                            Text(title, style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text(description),
                            const SizedBox(height: 28),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _MissingChallenge extends StatelessWidget {
  const _MissingChallenge({required this.message, required this.target});

  final String message;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_outlined, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(target),
                child: Text(context.strings.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
