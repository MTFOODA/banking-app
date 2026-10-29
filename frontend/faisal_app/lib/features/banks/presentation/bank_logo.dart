import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/entities/bank_definition.dart';

/// Reviewed official artwork, bundled for offline use; never recolored/rebuilt.
class BankLogo extends StatelessWidget {
  const BankLogo({super.key, required this.bank, this.size = 48});
  final BankDefinition bank;
  final double size;
  @override
  Widget build(BuildContext context) {
    final asset = bank.logoAsset;
    final label = bank.name(Localizations.localeOf(context).languageCode);
    Widget unavailable() => FittedBox(
      child: Text(
        bank.abbreviation.isEmpty ? bank.code : bank.abbreviation,
        style: TextStyle(
          color: Color(
            0xff000000 | int.parse(bank.primary.substring(1), radix: 16),
          ),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Semantics(
      label: label,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * .18),
        ),
        child: asset == null
            ? unavailable()
            : asset.endsWith('.svg')
            ? SvgPicture.asset(
                asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => unavailable(),
              )
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => unavailable(),
              ),
      ),
    );
  }
}
