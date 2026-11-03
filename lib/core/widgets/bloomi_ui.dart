import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'bloomi_design.dart';

class BloomiIcon extends StatelessWidget {
  const BloomiIcon(
    this.name, {
    this.size = 24,
    this.color = AppColors.primary,
    super.key,
  });
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/${name.replaceAll(':', '--')}.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class BloomiLogo extends StatelessWidget {
  const BloomiLogo({this.size = 40, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/bloomi-logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.high,
  );
}

class BloomiBrand extends StatelessWidget {
  const BloomiBrand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BloomiLogo(size: 40),
      SizedBox(width: 4),
      Text(
        'Bloomi',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class BloomiPage extends StatefulWidget {
  const BloomiPage({
    required this.children,
    this.header,
    this.quietHeader = false,
    super.key,
  });
  final Widget? header;
  final bool quietHeader;
  final List<Widget> children;
  @override
  State<BloomiPage> createState() => _BloomiPageState();
}

class _BloomiPageState extends State<BloomiPage> {
  final _controller = ScrollController();
  final _showTopBlur = ValueNotifier<bool>(false);
  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateBlur);
  }

  void _updateBlur() {
    final show = _controller.offset > 1;
    if (_showTopBlur.value != show) _showTopBlur.value = show;
  }

  @override
  void dispose() {
    _controller.dispose();
    _showTopBlur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ClipRect(
        child: Stack(
          children: [
            ListView(
              controller: _controller,
              padding: EdgeInsets.only(
                bottom: 168 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (widget.header != null)
                  widget.header!
                else if (widget.children.isNotEmpty &&
                    widget.children.first is BloomiTitle)
                  widget.quietHeader
                      ? Column(
                          children: [
                            const BloomiWave(
                              child: SizedBox(
                                height: 18,
                                width: double.infinity,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: widget.children.first,
                            ),
                          ],
                        )
                      : BloomiWaveHeader(
                          title: (widget.children.first as BloomiTitle).title,
                          subtitle:
                              (widget.children.first as BloomiTitle).subtitle,
                        ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children:
                        widget.header == null &&
                            widget.children.isNotEmpty &&
                            widget.children.first is BloomiTitle
                        ? widget.children.skip(1).toList()
                        : widget.children,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showTopBlur,
              builder: (context, show, _) => show
                  ? const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 112,
                      child: ProgressiveScrollBlur(top: true),
                    )
                  : const SizedBox.shrink(),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: ProgressiveScrollBlur(top: false),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fixed, gesture-transparent bands. Each shorter layer is stronger toward
/// the viewport edge; only the vertical axis is blurred.
class ProgressiveScrollBlur extends StatelessWidget {
  const ProgressiveScrollBlur({required this.top, super.key});
  final bool top;
  static const _strengths = [2.0, 4.0, 8.0, 12.0, 18.0];
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            for (var i = 0; i < 5; i++)
              Positioned(
                top: top ? 0 : null,
                bottom: top ? null : 0,
                left: 0,
                right: 0,
                height: constraints.maxHeight * (5 - i) / 5,
                child: ClipPath(
                  clipBehavior: Clip.antiAlias,
                  clipper: _ProgressiveBlurClipper(
                    top: top,
                    pixelRatio: MediaQuery.devicePixelRatioOf(context),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: _strengths[i]),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Fractional coverage at physical-pixel resolution gives the backdrop a
/// continuous alpha ramp without a ShaderMask saveLayer (which isolates the
/// backdrop and would prevent it from sampling the scrolling content).
class _ProgressiveBlurClipper extends CustomClipper<Path> {
  const _ProgressiveBlurClipper({required this.top, required this.pixelRatio});
  final bool top;
  final double pixelRatio;
  @override
  Path getClip(Size size) {
    final path = Path();
    final rows = (size.height * pixelRatio).ceil();
    for (var row = 0; row < rows; row++) {
      final position = (row + .5) / rows;
      final t = top ? 1 - position : position;
      final coverage = t * t * (3 - 2 * t);
      final y = row / pixelRatio;
      path.addRect(
        Rect.fromLTWH(
          0,
          y + (1 - coverage) / (2 * pixelRatio),
          size.width,
          coverage / pixelRatio,
        ),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(_ProgressiveBlurClipper oldClipper) =>
      oldClipper.top != top || oldClipper.pixelRatio != pixelRatio;
}

class BloomiTitle extends StatelessWidget {
  const BloomiTitle(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 16,
          height: 1.55,
        ),
      ),
    ],
  );
}

class BloomiSurface extends StatelessWidget {
  const BloomiSurface({
    required this.child,
    this.color = AppColors.surface,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: color == AppColors.surface
          ? [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .055),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    ),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: color == AppColors.surface
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class BloomiMetrics extends StatelessWidget {
  const BloomiMetrics({
    required this.donations,
    required this.points,
    this.showIcons = false,
    super.key,
  });
  final int donations;
  final int points;
  final bool showIcons;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _metric('Donaciones', donations, 'water-drop-outline-rounded'),
      ),
      const SizedBox(width: 12),
      Expanded(child: _metric('Puntos', points, 'star-outline-rounded')),
    ],
  );
  Widget _metric(String label, int value, String icon) => BloomiSurface(
    color: label == 'Donaciones'
        ? AppColors.blush
        : (showIcons ? AppColors.lavender : AppColors.butter),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BloomiIcon(
          'material-symbols:$icon',
          size: 28,
          color: label == 'Donaciones'
              ? AppColors.primaryDark
              : AppColors.butterInk,
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class BloomiNotice extends StatelessWidget {
  const BloomiNotice({
    required this.title,
    required this.detail,
    this.icon = 'verified-outline-rounded',
    this.color = AppColors.blush,
    super.key,
  });
  final String title;
  final String detail;
  final String icon;
  final Color color;
  @override
  Widget build(BuildContext context) => BloomiSurface(
    color: color,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: BloomiIcon('material-symbols:$icon'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
