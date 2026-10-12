import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/otp_boxes.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';

enum ChangePhoneStep { verifyOld, verifyNew }

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key, required this.step});

  final ChangePhoneStep step;

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _newPhone = TextEditingController();
  var _code = '';
  var _error = false;
  var _loading = false;
  var _seconds = AppConfig.otpResend.inSeconds;
  Timer? _timer;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.step == ChangePhoneStep.verifyOld) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final phone = ref.read(appControllerProvider).user?.phone ?? '';
        final national = phone.replaceAll(RegExp(r'\D'), '');
        final digits = national.length > 10
            ? national.substring(national.length - 10)
            : national;
        ref.read(appControllerProvider.notifier).sendOtp(digits);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newPhone.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = AppConfig.otpResend.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  Future<void> _verifyOld() async {
    if (_code.length != 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final phone = ref.read(appControllerProvider).user?.phone ?? '';
      final national = phone.replaceAll(RegExp(r'\D'), '');
      final digits = national.length > 10
          ? national.substring(national.length - 10)
          : national;
      await ref.read(appControllerProvider.notifier).verifyOtp(
            nationalNumber: digits,
            code: _code,
          );
      if (!mounted) return;
      context.push(AppRoutes.changePhoneNew);
    } on AuthException {
      setState(() => _error = true);
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendNewOtp() async {
    final digits = _newPhone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConfig.phoneLength) {
      setState(() => _fieldError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() {
      _fieldError = null;
      _loading = true;
    });
    try {
      await ref.read(appControllerProvider.notifier).sendOtp(
            digits,
            forceResend: true,
          );
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text('Code sent', style: AppTypography.bodyMedium),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _fieldError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fieldError = 'Could not send code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyNew() async {
    final digits = _newPhone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConfig.phoneLength) {
      setState(() => _fieldError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    if (_code.length != 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = false;
      _fieldError = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).changePhoneNumber(
            newNationalNumber: digits,
            newOtpCode: _code,
          );
      if (!mounted) return;
      context.go(AppRoutes.editProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Mobile number updated',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    } on AuthException {
      setState(() => _error = true);
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOld = widget.step == ChangePhoneStep.verifyOld;
    final current = ref.watch(appControllerProvider).user?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOld ? 'Verify current number' : 'New number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepHeader(step: isOld ? 1 : 2),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      isOld
                          ? 'Step 1 — verify your current number'
                          : 'Step 2 — verify your new number',
                      style: AppTypography.heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isOld
                          ? 'Enter the code sent to $current'
                          : 'Enter your new mobile number, then the OTP.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!isOld) ...[
                      StrykTextField(
                        controller: _newPhone,
                        hint: 'New mobile number',
                        keyboardType: TextInputType.phone,
                        maxLength: AppConfig.phoneLength,
                        errorText: _fieldError,
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            AppConfig.countryCode,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _loading ? null : _sendNewOtp,
                          child: Text(
                            'Send code',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    OtpBoxes(
                      length: 6,
                      error: _error,
                      onChanged: (value) {
                        setState(() {
                          _code = value;
                          _error = false;
                        });
                      },
                    ),
                    if (_error) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const ErrorState(message: 'That code doesn’t match.'),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        _seconds == 0
                            ? 'You can resend now'
                            : 'Resend in 0:${_seconds.toString().padLeft(2, '0')}',
                        style: AppTypography.label,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    StrykButton(
                      label: isOld ? 'Continue' : 'Update number',
                      loading: _loading,
                      enabled: _code.length == 6,
                      onPressed: isOld ? _verifyOld : _verifyNew,
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

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(1, step >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: step >= 2 ? AppColors.amber : AppColors.charcoal,
          ),
        ),
        _dot(2, step >= 2),
      ],
    );
  }

  Widget _dot(int n, bool active) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.amber : AppColors.charcoal,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$n',
        style: AppTypography.label.copyWith(
          color: active ? AppColors.textOnLight : AppColors.textMuted,
        ),
      ),
    );
  }
}
