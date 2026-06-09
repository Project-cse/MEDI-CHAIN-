import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_login_theme.dart';

class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.hintText,
    this.onFocusChange,
    this.premium = true,
    this.bottomGap = 20,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? hintText;
  final ValueChanged<bool>? onFocusChange;
  final bool premium;
  final double bottomGap;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool _focused = false;

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
    widget.onFocusChange?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.premium ? PremiumLoginTheme.fieldRadius : 12.0;
    final height = widget.premium ? PremiumLoginTheme.fieldHeight : 48.0;
    final labelColor = widget.premium ? PremiumLoginTheme.text : const Color(0xFF1F2937);
    final borderColor = _focused ? PremiumLoginTheme.accentBlue : PremiumLoginTheme.inputBorder;
    final borderWidth = _focused ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
            color: PremiumLoginTheme.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: PremiumLoginTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: PremiumLoginTheme.text,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: PremiumLoginTheme.placeholder,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => _setFocused(true),
                  onTapOutside: (_) => _setFocused(false),
                  onEditingComplete: () => _setFocused(false),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        if (widget.bottomGap > 0) SizedBox(height: widget.bottomGap),
      ],
    );
  }
}
