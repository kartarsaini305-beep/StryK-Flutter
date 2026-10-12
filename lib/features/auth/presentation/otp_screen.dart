import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_check.dart';
import '../../../../core/widgets/demo_chrome.dart';
import '../../../../core/widgets/otp_boxes.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../providers/app_controller.dart';
import '../../../../widgets/stryk_button.dart';
import '../../../../widgets/stryk_logo.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.nationalNumber});

  final String nationalNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  var _code = '';
  String? _errorMessage;
  var _loading = false;
  var _resending = false;
  var _success = false;
  var _seconds = AppConfig.otpResend.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoComplete());
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

  Future<void> _tryAutoComplete() async {
    final done = await ref
        .read(appControllerProvider.notifier)
        .completeIfFirebaseSignedIn(widget.nationalNumber);
    if (!mounted || !done || _success) return;
    await _finishSuccess();
  }

  Future<void> _finishSuccess() async {
    setState(() {
      _success = true;
      _loading = false;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final app = ref.read(appControllerProvider);
    if (app.hasName && app.hasGym) {
      context.go(AppRoutes.home);
    } else if (app.hasName) {
      context.go(AppRoutes.selectGym);
    } else {
      context.go(AppRoutes.name);
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6 || _loading || _success) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).verifyOtp(
            nationalNumber: widget.nationalNumber,
            code: _code,
          );
      if (!mounted) return;
      await _finishSuccess();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Try again.';
        _loading = false;
      });
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _resending || _loading || _success) return;
    setState(() {
      _resending = true;
      _errorMessage = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).sendOtp(
            widget.nationalNumber,
            forceResend: true,
          );
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text('Code sent', style: AppTypography.bodyMedium),
        ),
      );
      await _tryAutoComplete();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not resend code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = '${AppConfig.countryCode} ${widget.nationalNumber}';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _loading
              ? null
              : () {
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
                AppSpacing.lg + bottomInset,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: StrykLogo(height: 36, light: true)),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Enter the code',
                      style: AppTypography.heading.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We sent a 6-digit code to $phone',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_success)
                      const Center(child: AnimatedCheck(size: 64))
                    else
                      OtpBoxes(
                        length: 6,
                        error: _errorMessage != null,
                        onChanged: (value) {
                          if (_loading || _success) return;
                          setState(() {
                            _code = value;
                            _errorMessage = null;
                          });
                          if (value.length == 6) _verify();
                        },
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ErrorState(message: _errorMessage!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed:
                            _seconds == 0 && !_resending && !_loading && !_success
                                ? _resend
                                : null,
                        child: Text(
                          _resending
                              ? 'Sending…'
                              : _seconds == 0
                                  ? 'Resend code'
                                  : 'Resend in 0:${_seconds.toString().padLeft(2, '0')}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _seconds == 0 && !_resending
                                ? AppColors.amber
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: (constraints.maxHeight * 0.12).clamp(20, 64),
                    ),
                    StrykButton(
                      label: 'Verify',
                      loading: _loading,
                      enabled: _code.length == 6 && !_success && !_loading,
                      onPressed: _verify,
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
