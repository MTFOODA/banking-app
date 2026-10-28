import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/branding_config.dart';

Future<String?> pickBrandingColor(BuildContext context, String initial) =>
    showDialog<String>(
      context: context,
      builder: (_) => _Picker(initial: initial),
    );

class _Picker extends StatefulWidget {
  const _Picker({required this.initial});
  final String initial;
  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late var color = BrandingConfig.parseColor(widget.initial);
  late final controller = TextEditingController(text: widget.initial);
  bool valid = true;
  String hex(Color color) =>
      '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  void update(Color value) => setState(() {
    color = value;
    controller.text = hex(value);
    valid = true;
  });
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hsv = HSVColor.fromColor(color);
    return AlertDialog(
      title: Text(l.brandingHex),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in [
                    '#075C46',
                    '#0B795A',
                    '#C8A44D',
                    '#FFFFFF',
                    '#000000',
                    '#172923',
                    '#52635A',
                    '#1D4ED8',
                    '#7E22CE',
                    '#C83C42',
                    '#0B1F19',
                    '#F4F9F5',
                  ])
                    IconButton(
                      tooltip: value,
                      onPressed: () => update(BrandingConfig.parseColor(value)),
                      style: IconButton.styleFrom(
                        backgroundColor: BrandingConfig.parseColor(value),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      icon: Icon(
                        Icons.circle_outlined,
                        color:
                            BrandingConfig.contrastRatio(
                                  Colors.white,
                                  BrandingConfig.parseColor(value),
                                ) >
                                4.5
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: controller,
                textDirection: TextDirection.ltr,
                maxLength: 7,
                decoration: InputDecoration(
                  labelText: l.brandingHex,
                  errorText: valid ? null : l.brandingInvalid,
                ),
                onChanged: (text) => setState(() {
                  valid = RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(text);
                  if (valid) {
                    color = BrandingConfig.parseColor(text);
                  }
                }),
              ),
              for (final entry in [
                (l.brandingHue, hsv.hue, 360.0, (double v) => hsv.withHue(v)),
                (
                  l.brandingSaturation,
                  hsv.saturation,
                  1.0,
                  (double v) => hsv.withSaturation(v),
                ),
                (
                  l.brandingBrightness,
                  hsv.value,
                  1.0,
                  (double v) => hsv.withValue(v),
                ),
              ]) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(entry.$1),
                ),
                Slider(
                  value: entry.$2,
                  max: entry.$3,
                  label: entry.$2.toStringAsFixed(2),
                  semanticFormatterCallback: (v) =>
                      '${entry.$1}: ${v.toStringAsFixed(2)}',
                  onChanged: (v) => update(entry.$4(v).toColor()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, hex(color)) : null,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
