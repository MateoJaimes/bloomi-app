import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared visual language from the approved Bloomi mockups.
class BloomiWave extends StatelessWidget {
  const BloomiWave({required this.child, this.contours = true, super.key});
  final Widget child;
  final bool contours;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _WavePainter(contours),
    child: Padding(padding: const EdgeInsets.only(bottom: 48), child: child),
  );
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.contours);
  final bool contours;
  Path _shape(Size s, double offset) => Path()
    ..lineTo(0, s.height - 32 + offset)
    ..cubicTo(
      s.width * .25,
      s.height - 85 + offset,
      s.width * .44,
      s.height + 15 + offset,
      s.width * .70,
      s.height - 22 + offset,
    )
    ..quadraticBezierTo(
      s.width * .9,
      s.height - 48 + offset,
      s.width,
      s.height - 30 + offset,
    )
    ..lineTo(s.width, 0)
    ..close();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_shape(size, 12), Paint()..color = AppColors.softRose);
    final shape = _shape(size, 0);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ).createShader(Offset.zero & size),
    );
    if (!contours) return;
    canvas.save();
    canvas.clipPath(shape);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = 12.0 + i * 13;
      canvas.drawPath(
        Path()
          ..moveTo(-25, y)
          ..cubicTo(
            size.width * .25,
            y + 100,
            size.width * .5,
            y - 90,
            size.width + 30,
            y + 28,
          ),
        line,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.contours != contours;
}

class BloomiWaveHeader extends StatelessWidget {
  const BloomiWaveHeader({
    required this.title,
    this.subtitle,
    this.showBack = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final bool showBack;
  @override
  Widget build(BuildContext context) => BloomiWave(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: 'Volver',
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  title,
                  textAlign: showBack ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: title.length > 18 ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              if (showBack) const SizedBox(width: 48),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class BloomiEmblem extends StatelessWidget {
  const BloomiEmblem(
    this.icon, {
    this.size = 88,
    this.background = AppColors.blush,
    this.foreground = AppColors.primaryDark,
    super.key,
  });
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Icon(icon, size: size * .52, color: foreground),
  );
}

class BloomiPill extends StatelessWidget {
  const BloomiPill(
    this.label, {
    this.color = AppColors.blush,
    this.foreground = AppColors.primaryDark,
    this.icon,
    super.key,
  });
  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class BloomiFormLayout extends StatelessWidget {
  const BloomiFormLayout({
    required this.title,
    required this.children,
    this.formKey,
    this.emblem,
    this.illustration,
    this.step,
    this.showBack = true,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final GlobalKey<FormState>? formKey;
  final IconData? emblem;
  final Widget? illustration;
  final String? step;
  final bool showBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            key: PageStorageKey('form-$title'),
            padding: EdgeInsets.only(
              bottom: 32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              BloomiWaveHeader(title: title, showBack: showBack),
              if (illustration != null) ...[
                Center(child: illustration!),
                const SizedBox(height: 20),
              ] else if (emblem != null) ...[
                Center(child: BloomiEmblem(emblem!, size: 88)),
                const SizedBox(height: 20),
              ],
              if (step != null) ...[
                Center(child: BloomiPill(step!)),
                const SizedBox(height: 18),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BloomiFieldPair extends StatelessWidget {
  const BloomiFieldPair({required this.first, required this.second, super.key});
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 18
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 14), second],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
  );
}

class BloomiDonorAvatar extends StatelessWidget {
  const BloomiDonorAvatar({required this.initial, this.bloodType, super.key});
  final String initial;
  final String? bloodType;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 108,
    height: 108,
    child: Stack(
      children: [
        Container(
          width: 98,
          height: 98,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.softRose, width: 5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
        ),
        if (bloodType != null && bloodType!.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surface, width: 3),
              ),
              child: Text(
                bloodType!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
