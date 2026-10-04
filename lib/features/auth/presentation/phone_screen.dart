import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/demo_chrome.dart';
import '../../../../core/widgets/stryk_text_field.dart';
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
      await ref.read(appControllerProvider.notifier).sendOtp(digits);
      if (!mounted) return;
      context.push(AppRoutes.otpFor(digits));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DemoModeBadge(),
                      const SizedBox(height: AppSpacing.lg),
                      const StrykLogo(height: 32, light: true),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Your phone', style: AppTypography.heading),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We’ll send a 6-digit code. In demo mode, nothing is actually sent.',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      StrykTextField(
                        controller: _controller,
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                        maxLength: AppConfig.phoneLength,
                        autofocus: true,
                        errorText: _error,
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              AppConfig.countryCode,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _submit(),
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      StrykButton(
                        label: 'Send code',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => context.push(AppRoutes.adminLogin),
                        child: Text(
                          'Admin Login',
                          style: AppTypography.button.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
