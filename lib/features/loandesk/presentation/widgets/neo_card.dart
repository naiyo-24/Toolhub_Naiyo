import 'package:flutter/material.dart';
import '../theme/loandesk_theme.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = LoanDeskTheme.primaryWhite,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
