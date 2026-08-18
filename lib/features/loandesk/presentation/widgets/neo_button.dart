import 'package:flutter/material.dart';
import '../theme/loandesk_theme.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool isFullWidth;
  final IconData? icon;
  final String? imageAsset;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = LoanDeskTheme.primaryYellow,
    this.textColor = LoanDeskTheme.primaryBlack,
    this.isFullWidth = false,
    this.icon,
    this.imageAsset,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.isFullWidth ? double.infinity : null,
        transform: Matrix4.translationValues(
          _isPressed ? LoanDeskTheme.shadowOffset : 0.0,
          _isPressed ? LoanDeskTheme.shadowOffset : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
          border: Border.all(
            color: LoanDeskTheme.primaryBlack,
            width: LoanDeskTheme.borderWidth,
          ),
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(
                    color: LoanDeskTheme.primaryBlack,
                    offset: Offset(
                      LoanDeskTheme.shadowOffset,
                      LoanDeskTheme.shadowOffset,
                    ),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.imageAsset != null) ...[
              Image.asset(
                widget.imageAsset!,
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 8),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 15, // Reduced from 16 to fit without overflow
              ),
            ),
          ],
        ),
      ),
    );
  }
}
