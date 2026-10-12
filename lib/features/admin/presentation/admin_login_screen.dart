import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';
import '../services/admin_auth_service.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  var _step = 0;
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).sendAdminOtp(digits);
      if (!mounted) return;
      setState(() => _step = 1);
    } on AdminAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not start admin login.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final code = _otp.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).verifyAdminOtp(
            nationalNumber: digits,
            code: code,
          );
      if (!mounted) return;
      if (context.canPop()) {
        context.pushReplacement(AppRoutes.admin);
      } else {
        context.go(AppRoutes.admin);
      }
    } on AdminAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Admin verification failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Login',
          style: AppTypography.subheading.copyWith(color: AppColors.error),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: [
            const Center(child: StrykLogo(height: 28, light: true)),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
              ),
              child: Text(
                'Restricted access. Admin authentication only.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _step == 0 ? 'Admin phone' : 'Enter admin code',
              style: AppTypography.heading.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _step == 0
                  ? 'Use the registered admin mobile number.'
                  : 'Demo code for local MVP: ${AppConfig.demoOtp}',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_step == 0)
              StrykTextField(
                controller: _phone,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
                maxLength: AppConfig.phoneLength,
                autofocus: true,
                errorText: _error,
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Text(AppConfig.countryCode, style: AppTypography.bodyMedium),
                ),
              )
            else
              StrykTextField(
                controller: _otp,
                hint: '6-digit code',
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                errorText: _error,
              ),
            const SizedBox(height: AppSpacing.xl),
            StrykButton(
              label: _step == 0 ? 'Send admin code' : 'Enter admin panel',
              loading: _loading,
              onPressed: _step == 0 ? _send : _verify,
            ),
            if (_step == 1) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => setState(() {
                  _step = 0;
                  _error = null;
                }),
                child: Text(
                  'Change number',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
