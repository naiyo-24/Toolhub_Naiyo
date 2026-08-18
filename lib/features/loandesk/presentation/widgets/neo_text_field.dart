import 'package:flutter/material.dart';
import '../theme/loandesk_theme.dart';

class NeoTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const NeoTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      initialValue: controller?.text,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: LoanDeskTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: LoanDeskTheme.primaryWhite,
                borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                border: Border.all(
                  color: state.hasError ? LoanDeskTheme.primaryRed : LoanDeskTheme.primaryBlack,
                  width: LoanDeskTheme.borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: LoanDeskTheme.primaryBlack,
                    offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onChanged: (value) {
                  state.didChange(value);
                },
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: LoanDeskTheme.primaryBlack,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: LoanDeskTheme.primaryBlack.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: LoanDeskTheme.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
