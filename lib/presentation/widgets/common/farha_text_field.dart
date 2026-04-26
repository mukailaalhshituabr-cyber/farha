// lib/presentation/widgets/common/farha_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class FarhaTextField extends StatelessWidget {
  final TextEditingController?  controller;
  final String                  label;
  final String?                 hint;
  final IconData?               prefixIcon;
  final Widget?                 suffixIcon;
  final bool                    obscureText;
  final TextInputType           keyboardType;
  final TextInputAction         textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)?  onChanged;
  final void Function(String)?  onFieldSubmitted;
  final bool                    readOnly;
  final int                     maxLines;
  final List<TextInputFormatter> inputFormatters;
  final bool                    enabled;
  final String?                 initialValue;

  const FarhaTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText       = false,
    this.keyboardType      = TextInputType.text,
    this.textInputAction   = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.readOnly          = false,
    this.maxLines          = 1,
    this.inputFormatters   = const [],
    this.enabled           = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:       controller,
      initialValue:     controller == null ? initialValue : null,
      obscureText:      obscureText,
      keyboardType:     keyboardType,
      textInputAction:  textInputAction,
      validator:        validator,
      onChanged:        onChanged,
      onFieldSubmitted: onFieldSubmitted,
      readOnly:         readOnly,
      maxLines:         obscureText ? 1 : maxLines,
      enabled:          enabled,
      inputFormatters:  inputFormatters,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize:   15,
        color:      AppColors.onBackground,
      ),
      decoration: InputDecoration(
        labelText:   label,
        hintText:    hint,
        prefixIcon:  prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon:  suffixIcon,
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────
class FarhaDropdown<T> extends StatelessWidget {
  final T?                    value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)     onChanged;
  final String                label;
  final IconData?             prefixIcon;
  final String? Function(T?)? validator;

  const FarhaDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue:     value,
      items:     items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.onBackground),
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      ),
    );
  }
}
