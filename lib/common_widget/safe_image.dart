import 'package:flutter/material.dart';

/// Builds an Image.asset that won’t throw if the asset is missing.
/// Falls back to a simple placeholder icon.
Widget safeAsset(
  String path, {
  double? width,
  double? height,
  Color? color,
  BoxFit? fit,
}) {
  return Image.asset(
    path,
    width: width,
    height: height,
    color: color,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      final fallbackSize = (width ?? height ?? 20).toDouble();
      return Icon(
        Icons.image_not_supported,
        size: fallbackSize,
        color: color ?? Colors.grey,
      );
    },
  );
}
