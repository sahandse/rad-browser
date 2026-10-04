import 'package:flutter/material.dart';

import '../../../../core/theme/rad_theme.dart';

class RadSearchBar extends StatefulWidget {
  const RadSearchBar({super.key, this.onSubmitted});

  final ValueChanged<String>? onSubmitted;

  @override
  State<RadSearchBar> createState() => _RadSearchBarState();
}

class _RadSearchBarState extends State<RadSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.go,
      onSubmitted: widget.onSubmitted,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'جستجو یا وارد کردن آدرس',
        hintTextDirection: TextDirection.rtl,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: 'اسکن QR',
          onPressed: () {},
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      ),
      style: const TextStyle(fontSize: 16, color: RadColors.text),
    );
  }
}
