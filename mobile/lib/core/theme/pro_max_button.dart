import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProMaxButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final Widget? icon;

  const ProMaxButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.icon,
  });

  @override
  State<ProMaxButton> createState() => _ProMaxButtonState();
}

class _ProMaxButtonState extends State<ProMaxButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isSecondary
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brandStrong],
                  ),
            color: widget.isSecondary
                ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                : null,
            border: widget.isSecondary
                ? Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.line,
                  )
                : null,
            boxShadow: isDisabled
                ? null
                : widget.isSecondary
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        // Inner highlight simulation
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        )
                      ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isSecondary
                      ? (isDark ? AppColors.inkDark : AppColors.ink)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
