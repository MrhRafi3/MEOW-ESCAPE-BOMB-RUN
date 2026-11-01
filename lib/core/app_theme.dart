import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // THEME COLORS
  static const Color bgDark = Color(0xFF0A0A12);
  static const Color surfaceDark = Color(0xFF141422);
  static const Color cardDark = Color(0xFF1A1A2E);
  static const Color cardBorder = Color(0xFF2E2E48);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color neonRed = Color(0xFFFF1744);
  static const Color neonGold = Color(0xFFFFD600);

  // TEXT STYLES
  static const TextStyle arcadeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 10, color: neonCyan, offset: Offset(0, 0)),
      Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
    ],
  );

  static const TextStyle arcadeSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 3.0,
    color: neonGold,
    shadows: [
      Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1, 1)),
    ],
  );

  static const TextStyle scoreHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
    ],
  );
}

class ArcadeButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color textColor;
  final double width;
  final double height;

  const ArcadeButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.primaryColor = AppTheme.neonCyan,
    this.textColor = Colors.black,
    this.width = 240,
    this.height = 54,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryColor,
                widget.primaryColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
