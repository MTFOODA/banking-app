import 'package:flutter/material.dart';

String cardVariant(String code) => switch (code) {
  'CP-PLATINUM-DEBIT' || 'CP-PLATINUM-CREDIT' => 'platinum',
  'CP-PLATINUM-FX' => 'platinum_fx',
  'CP-YOUTH-DEBIT' => 'youth',
  'CP-MEEZA-DEBIT' => 'meeza',
  'CP-MEEZA-BAB-REZQ' => 'meeza_bab_rezq',
  _ => 'gold',
};

LinearGradient cardGradient(String variant) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: switch (variant) {
    'platinum' => const [
      Color(0xff090f0d),
      Color(0xff143f33),
      Color(0xff080d0c),
    ],
    'platinum_fx' => const [
      Color(0xff080c0b),
      Color(0xff242719),
      Color(0xff826c25),
    ],
    'youth' => const [Color(0xff116c52), Color(0xff0b463d), Color(0xff5b792d)],
    'meeza' => const [Color(0xff163d29), Color(0xff47733a), Color(0xff686323)],
    'meeza_bab_rezq' => const [
      Color(0xff6e5b1c),
      Color(0xff3b5a24),
      Color(0xff123d30),
    ],
    _ => const [Color(0xff75601e), Color(0xff254e32), Color(0xff064536)],
  },
);

/// Shared vector artwork for product previews and actual owned cards.
class CardArtwork extends CustomPainter {
  const CardArtwork(this.variant);
  final String variant;
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xffd7bd69).withValues(alpha: .23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final green = Paint()
      ..color = const Color(0xff5db78c).withValues(alpha: .14);
    switch (variant) {
      case 'platinum':
        for (var i = 0; i < 7; i++) {
          canvas.drawLine(
            Offset(size.width * .5 + i * 21, -5),
            Offset(size.width * .1 + i * 21, size.height + 5),
            gold,
          );
        }
      case 'platinum_fx':
        for (var i = 0; i < 4; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                size.width * .50 + i * 15,
                -size.height * .2,
                65,
                size.height * 1.4,
              ),
              const Radius.circular(30),
            ),
            gold,
          );
        }
      case 'youth':
        final path = Path()
          ..moveTo(0, size.height * .75)
          ..cubicTo(
            size.width * .3,
            0,
            size.width * .6,
            size.height * 1.5,
            size.width,
            size.height * .3,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, green);
        canvas.drawCircle(
          Offset(size.width * .85, size.height * .18),
          size.height * .38,
          gold,
        );
      case 'meeza':
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(size.width * .9, size.height * .6),
            35.0 + i * 24,
            gold,
          );
        }
      case 'meeza_bab_rezq':
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              size.width * .50 + i * 20,
              size.height * .6 - i * 15,
              36,
              size.height,
            ),
            gold,
          );
        }
      default:
        final path = Path()
          ..moveTo(size.width * .65, 0)
          ..lineTo(size.width, size.height * .5)
          ..lineTo(size.width * .65, size.height)
          ..lineTo(size.width * .30, size.height * .5)
          ..close();
        canvas.drawPath(path, gold);
        canvas.drawCircle(Offset(size.width * .9, 10), 70, green);
    }
  }

  @override
  bool shouldRepaint(CardArtwork oldDelegate) => oldDelegate.variant != variant;
}
