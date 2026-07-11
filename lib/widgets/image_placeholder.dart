import 'dart:io';
import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Grey box with a picture icon — used all over the wireframe (Welcome
/// screens, Home feed images, Emotion Analysis preview, avatars, etc).
/// If [imageFile] is provided it renders that image instead of the icon.
class ImagePlaceholderBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final File? imageFile;
  final IconData icon;

  const ImagePlaceholderBox({
    super.key,
    this.height = 140,
    this.width,
    this.borderRadius = 10,
    this.imageFile,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: AppColors.placeholder,
        child: imageFile != null
            ? Image.file(imageFile!, fit: BoxFit.cover)
            : Icon(icon, size: 36, color: AppColors.textSecondary),
      ),
    );
  }
}