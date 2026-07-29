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

/// Multicolor Gmail mark rendered as vector strokes so it remains crisp and
/// keeps its recognizable Google colors at every device density.
class GmailBrandMark extends StatelessWidget {
  final double size;

  const GmailBrandMark({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gmail',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _GmailBrandPainter(),
      ),
    );
  }
}

class _GmailBrandPainter extends CustomPainter {
  const _GmailBrandPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC04);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .155;
    Paint segment(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round;

    final leftTop = Offset(size.width * .13, size.height * .24);
    final center = Offset(size.width * .5, size.height * .52);
    final rightTop = Offset(size.width * .87, size.height * .24);
    final bottom = size.height * .8;

    canvas.drawLine(
      leftTop,
      Offset(size.width * .13, bottom),
      segment(_blue),
    );
    canvas.drawLine(leftTop, center, segment(_red));
    canvas.drawLine(center, rightTop, segment(_yellow));
    canvas.drawLine(
      rightTop,
      Offset(size.width * .87, bottom),
      segment(_green),
    );
  }

  @override
  bool shouldRepaint(covariant _GmailBrandPainter oldDelegate) => false;
}
