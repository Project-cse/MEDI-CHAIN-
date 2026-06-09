import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_healthcare_theme.dart';

class PremiumPatientFormField extends StatelessWidget {
  const PremiumPatientFormField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: PremiumHealthcareTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: PremiumHealthcareTheme.fieldHeight,
          decoration: BoxDecoration(
            color: PremiumHealthcareTheme.white,
            borderRadius: BorderRadius.circular(PremiumHealthcareTheme.fieldRadius),
            border: Border.all(color: PremiumHealthcareTheme.border),
            boxShadow: PremiumHealthcareTheme.fieldShadow,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: PremiumHealthcareTheme.text,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumPatientDropdownField extends StatelessWidget {
  const PremiumPatientDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: PremiumHealthcareTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: PremiumHealthcareTheme.fieldHeight,
          decoration: BoxDecoration(
            color: PremiumHealthcareTheme.white,
            borderRadius: BorderRadius.circular(PremiumHealthcareTheme.fieldRadius),
            border: Border.all(color: PremiumHealthcareTheme.border),
            boxShadow: PremiumHealthcareTheme.fieldShadow,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                const SizedBox(width: 12),
                Icon(icon, size: 20, color: PremiumHealthcareTheme.secondaryBlue),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: PremiumHealthcareTheme.textSecondary),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: PremiumHealthcareTheme.text,
                    ),
                    items: items
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PremiumContinueButton extends StatelessWidget {
  const PremiumContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !loading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: PremiumHealthcareTheme.ctaHeight,
      decoration: BoxDecoration(
        gradient: active ? PremiumHealthcareTheme.ctaGradient : null,
        color: active ? null : PremiumHealthcareTheme.border,
        borderRadius: BorderRadius.circular(PremiumHealthcareTheme.ctaRadius),
        boxShadow: active ? PremiumHealthcareTheme.ctaShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(PremiumHealthcareTheme.ctaRadius),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : PremiumHealthcareTheme.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
