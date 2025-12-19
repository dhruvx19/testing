import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';

class ThankYou extends StatefulWidget {
  const ThankYou({super.key});

  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  late int _tempRating;

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 142,
            height: 110,
            child: Image.asset(
              EcliniqIcons.thankYou.assetPath,
              fit: BoxFit.contain,
            ),
          ),

          Text(
            'Thank you for your Valuable Feedback!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),

          const SizedBox(height: 22),

          _buildSubmitButton(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTapUp: (_) {
          Navigator.of(context).pop(_tempRating);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xff8E8E8E), width: 0.5),
          ),
          child: const Center(
            child: Text(
              'Ok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xff424242),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
