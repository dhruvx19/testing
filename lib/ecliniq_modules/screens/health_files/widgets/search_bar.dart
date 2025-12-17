import 'dart:async';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.onBack,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search Doctors',
    this.showBackButton = false,
    this.autofocus = false,
    this.onVoiceSearch,
    this.controller,
  });

  final VoidCallback? onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final String hintText;
  final bool showBackButton;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String query = '';
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
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
        const SnackBar(
          content: Text('Voice search feature coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Color(0xff626060)),
      ),
      child: Animate(
        effects: const [
          FadeEffect(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ],
        child: TextField(
          autofocus: widget.autofocus,
          controller: _controller,
          decoration: InputDecoration(
            enabledBorder: outlinedBorder,
            focusedBorder: outlinedBorder,
            border: outlinedBorder,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            suffixIcon: query.isNotEmpty
                ? Animate(
                    effects: const [
                      FadeEffect(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                    ],
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        if (widget.onClear != null) {
                          widget.onClear!();
                        }
                        setState(() => query = '');
                        _controller.clear();
                      },
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: _handleVoiceSearch,
                      child: SvgPicture.asset(
                        EcliniqIcons.microphoneMyDoctor.assetPath,
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
            prefixIcon: widget.showBackButton
                ? IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(left: 4.0),
                    child: Image.asset(
                      EcliniqIcons.magnifierMyDoctor.assetPath,
                      width: 20,
                      height: 20,
                    ),
                  ),
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 14.0,
            ),
          ),
          onChanged: search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlignVertical: TextAlignVertical.center,
          cursorColor: Colors.blue,
          cursorWidth: 1.5,
          cursorHeight: 20,
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ),
    );
  }
}
