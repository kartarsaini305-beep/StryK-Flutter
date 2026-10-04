import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.length,
    required this.onChanged,
    this.error = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool error;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            autofocus: true,
            showCursor: false,
            enableInteractiveSelection: true,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: false,
            ),
            onChanged: (text) {
              setState(() {});
              widget.onChanged(text);
            },
          ),
          IgnorePointer(
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Box(
                      char: i < value.length ? value[i] : '',
                      focused: value.length == i && _focus.hasFocus,
                      error: widget.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.char,
    required this.focused,
    required this.error,
  });

  final String char;
  final bool focused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final border = error
        ? AppColors.error
        : focused
            ? AppColors.amber
            : AppColors.borderSubtle;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: focused || error ? 1.4 : 1),
        ),
        child: Center(
          child: Text(
            char,
            style: AppTypography.heading.copyWith(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
