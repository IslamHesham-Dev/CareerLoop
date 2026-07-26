import 'package:flutter/material.dart';

/// Code-rendered so the LinkedIn mark cannot disappear through icon-font
/// tree-shaking in release builds.
class LinkedInBrandMark extends StatelessWidget {
  final double size;

  const LinkedInBrandMark({
    super.key,
    this.size = 42,
  });

  static const blue = Color(0xFF0A66C2);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Transform.translate(
        offset: Offset(0, -size * .025),
        child: Text(
          'in',
          semanticsLabel: 'LinkedIn',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * .53,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * .035,
          ),
        ),
      ),
    );
  }
}
