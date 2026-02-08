import 'dart:async';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.onBack,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search Doctor',
    this.showBackButton = false,
    this.autofocus = false,
    this.onVoiceSearch,
    this.controller,
    this.onTap,
    this.isListening = false,
  });

  final VoidCallback? onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onTap;
  final String hintText;
  final bool showBackButton;
  final bool autofocus;
  final TextEditingController? controller;
  final bool isListening;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String query = '';
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    query = _controller.text;

    _controller.addListener(_onControllerChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onControllerChanged);
      query = _controller.text;
    }
  }

  void _onControllerChanged() {
    if (mounted && _controller.text != query) {
      setState(() {
        query = _controller.text;
      });
    }
  }

  Future<void> search(String text) async {
    setState(() => query = text);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }

  void _handleVoiceSearch() {
    if (widget.onVoiceSearch != null) {
      widget.onVoiceSearch!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: EcliniqText('Voice search feature coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearSearch() {
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() => query = '');
    _controller.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();

    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 14,
        vertical: 8,
      ),
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
        ),
        border: Border.all(color: Color(0xFF626060), width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 12,
              right: 8,
              top: 0,
              bottom: 0,
            ),
            child: SvgPicture.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: AbsorbPointer(
                absorbing: widget.onTap != null,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: search,
                  textInputAction: TextInputAction.search,
                  style: EcliniqTextStyles.responsiveTitleXLarge(
                    context,
                  ).copyWith(color: Color(0xFF424242)),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xFF8E8E8E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  cursorColor: Color(0xFF2372EC),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
            ),
          ),

          if (query.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 12,
                  vertical: 0,
                ),
                child: Icon(
                  Icons.close,
                  color: Color(0xFF9E9E9E),
                  size: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _handleVoiceSearch,
              child: Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  right: 8,
                  top: 0,
                  bottom: 0,
                  left: 0,
                ),
                child: SvgPicture.asset(
                  EcliniqIcons.microphone.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  colorFilter: widget.isListening
                      ? const ColorFilter.mode(
                          Color(0xFF2372EC),
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
