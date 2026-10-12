import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stryk_text_field.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../providers/app_controller.dart';
import '../../../../widgets/stryk_button.dart';
import '../../../../widgets/stryk_logo.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  String? _error;
  var _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConfig.phoneLength) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final controller = ref.read(appControllerProvider.notifier);
      await controller.sendOtp(digits);
      if (!mounted) return;
      final autoDone = await controller.completeIfFirebaseSignedIn(digits);
      if (!mounted) return;
      if (autoDone) {
        final app = ref.read(appControllerProvider);
        if (app.hasName && app.hasGym) {
          context.go(AppRoutes.home);
        } else if (app.hasName) {
          context.go(AppRoutes.selectGym);
        } else {
          context.go(AppRoutes.name);
        }
        return;
      }
      context.push(AppRoutes.otpFor(digits));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.onboarding);
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: StrykLogo(height: 40, light: true)),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back',
                      style: AppTypography.heading.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your mobile number. We’ll send a 6-digit code.',
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    StrykTextField(
                      controller: _controller,
                      label: 'Mobile number',
                      hint: '10-digit number',
                      keyboardType: TextInputType.phone,
                      maxLength: AppConfig.phoneLength,
                      autofocus: true,
                      errorText: _error,
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Center(
                          widthFactor: 1,
                          child: Text(AppConfig.countryCode, style: AppTypography.bodyMedium),
                        ),
                      ),
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _submit(),
                    ),
                    SizedBox(height: (constraints.maxHeight * 0.16).clamp(24.0, 72.0)),
                    StrykButton(
                      label: 'Send OTP',
                      loading: _loading,
                      enabled: !_loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.adminLogin),
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      label: Text(
                        'Admin Login',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
