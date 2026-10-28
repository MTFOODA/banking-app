import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';

class FaisalLoadingView extends StatefulWidget {
  const FaisalLoadingView({super.key, this.lines = 3});

  final int lines;

  @override
  State<FaisalLoadingView> createState() => _FaisalLoadingViewState();
}

class _FaisalLoadingViewState extends State<FaisalLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.palette.mintSurface;
    final highlight = context.colors.surfaceContainerHigh;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _controller.value) ?? base;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.lines,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              height: index == 0 ? 96 : 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.palette.outline),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FaisalListSkeleton extends StatelessWidget {
  const FaisalListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final base = context.palette.mintSurface;
    return Column(
      children: List.generate(
        rows,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          height: 64,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
