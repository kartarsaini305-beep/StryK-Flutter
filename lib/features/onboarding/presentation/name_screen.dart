import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  late final TextEditingController _controller;
  String? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(appControllerProvider).user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name to continue.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    await ref.read(appControllerProvider.notifier).saveName(name);
    if (!mounted) return;
    context.go(AppRoutes.selectGym);
  }

  @override
  Widget build(BuildContext context) {
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
              Text("What's your name?", style: AppTypography.heading),
              const SizedBox(height: AppSpacing.xl),
              StrykTextField(
                controller: _controller,
                hint: 'Your name',
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                errorText: _error,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
              ),
              const Spacer(),
              StrykButton(
                label: 'Continue',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
