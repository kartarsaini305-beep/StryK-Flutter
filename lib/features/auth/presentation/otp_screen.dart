import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config.dart';
import '../../../../core/constants/app_copy.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_check.dart';
import '../../../../core/widgets/demo_chrome.dart';
import '../../../../core/widgets/otp_boxes.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../providers/app_controller.dart';
import '../../../../widgets/stryk_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.nationalNumber});

  final String nationalNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  var _code = '';
  var _error = false;
  var _loading = false;
  var _success = false;
  var _seconds = AppConfig.otpResend.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _verify() async {
    if (_code.length != 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await ref.read(appControllerProvider.notifier).verifyOtp(
            nationalNumber: widget.nationalNumber,
            code: _code,
          );
      if (!mounted) return;
      setState(() {
        _success = true;
        _loading = false;
      });
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.go(AppRoutes.name);
    } on AuthException {
      setState(() {
        _error = true;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    await ref.read(appControllerProvider.notifier).sendOtp(widget.nationalNumber);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final phone = '${AppConfig.countryCode} ${widget.nationalNumber}';
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoModeBadge(),
              const SizedBox(height: AppSpacing.lg),
              Text('Enter the 6-digit code sent to your phone', style: AppTypography.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(phone, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              Text(AppCopy.demoOtpHint, style: AppTypography.label),
              const SizedBox(height: AppSpacing.xl),
              if (_success)
                const Center(child: AnimatedCheck(size: 64))
              else
                OtpBoxes(
                  length: 6,
                  error: _error,
                  onChanged: (value) {
                    setState(() {
                      _code = value;
                      _error = false;
                    });
                    if (value.length == 6) _verify();
                  },
                ),
              if (_error) ...[
                const SizedBox(height: AppSpacing.md),
                const ErrorState(message: 'That code doesn’t match. Try 123456.'),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: _seconds == 0 ? _resend : null,
                  child: Text(
                    _seconds == 0 ? 'Resend code' : 'Resend in 0:${_seconds.toString().padLeft(2, '0')}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _seconds == 0 ? AppColors.amber : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              StrykButton(
                label: 'Verify',
                loading: _loading,
                enabled: _code.length == 6 && !_success,
                onPressed: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
