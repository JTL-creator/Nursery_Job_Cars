import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum GdmButtonVariant { primary, secondary, danger, ghost }

class GdmButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final IconData? icon;
  final GdmButtonVariant variant;
  final bool expand;

  const GdmButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.icon,
    this.variant = GdmButtonVariant.primary,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (variant) {
      case GdmButtonVariant.secondary:
        bg = AppColors.gdmBlue;
        fg = Colors.white;
        break;
      case GdmButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        break;
      case GdmButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.gdmBlue;
        break;
      case GdmButtonVariant.primary:
        bg = AppColors.gdmLime;
        fg = AppColors.gdmBlue;
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if ((loading || icon != null)) const SizedBox(width: 8),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ],
    );

    final btn = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: variant == GdmButtonVariant.ghost ? 0 : 1,
        side: variant == GdmButtonVariant.ghost
            ? const BorderSide(color: AppColors.gdmBlue)
            : BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: loading ? null : onPressed,
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
