import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeoCard extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderWidth = 3.0,
    this.borderRadius = 12.0,
    this.shadowOffset = const Offset(4, 4),
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.width,
    this.height,
    this.margin,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        margin: _isPressed 
            ? EdgeInsets.only(
                left: widget.shadowOffset.dx, 
                top: widget.shadowOffset.dy,
              )
            : EdgeInsets.only(
                right: widget.shadowOffset.dx, 
                bottom: widget.shadowOffset.dy,
              ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
            width: widget.borderWidth,
          ),
          boxShadow: _isPressed 
              ? [] 
              : [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    offset: widget.shadowOffset,
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );

    if (widget.margin != null) {
      return Padding(
        padding: widget.margin!,
        child: card,
      );
    }
    
    return card;
  }
}
