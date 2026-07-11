//REUSABLE BUTTONS
import 'package:flutter/material.dart';
import '../app_theme.dart';

/// A full-width rounded button. Pass [isAccent] to get the yellow
/// "GET STARTED" style instead of the default navy style.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isAccent;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isAccent = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isAccent ? AppColors.accent : AppColors.primary,
          foregroundColor: isAccent ? AppColors.textPrimary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isAccent ? AppColors.textPrimary : Colors.white,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
      ),
    );
  }
}
