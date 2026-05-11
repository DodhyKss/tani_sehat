import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive utility class for adapting UI to all device sizes.
/// Uses a baseline width of 375 (iPhone SE / compact phones).
class Responsive {
  static late MediaQueryData _mediaQuery;
  static late double _screenWidth;
  static late double _screenHeight;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
    _screenWidth = _mediaQuery.size.width;
    _screenHeight = _mediaQuery.size.height;
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static EdgeInsets get padding => _mediaQuery.padding;

  // Base design width (iPhone SE-class)
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  /// Scale factor relative to base width
  static double get _scaleFactor {
    final scale = _screenWidth / _baseWidth;
    // Clamp to avoid extreme scaling on tablets or very small devices
    return scale.clamp(0.8, 1.4);
  }

  /// Scale a width value relative to base screen width
  static double w(double size) => size * _scaleFactor;

  /// Scale a height value relative to base screen height
  static double h(double size) {
    final scale = (_screenHeight / _baseHeight).clamp(0.8, 1.4);
    return size * scale;
  }

  /// Scale font size with clamping to prevent extremes
  static double sp(double size) {
    final scaled = size * _scaleFactor;
    // Don't let text become too small or too big
    return scaled.clamp(size * 0.85, size * 1.35);
  }

  /// Responsive icon size
  static double icon(double size) => w(size);

  /// Get responsive padding value
  static double pad(double size) => w(size);

  /// Responsive radius
  static double radius(double size) => w(size);

  /// Is this a small phone (width < 360)
  static bool get isSmallPhone => _screenWidth < 360;

  /// Is this a regular phone (360-414)
  static bool get isPhone => _screenWidth >= 360 && _screenWidth < 600;

  /// Is this a tablet (width >= 600)
  static bool get isTablet => _screenWidth >= 600;

  /// Number of grid columns based on screen width
  static int get gridColumns {
    if (_screenWidth >= 900) return 4;
    if (_screenWidth >= 600) return 3;
    return 3; // default for phones
  }

  /// Max content width (useful for centering on tablets)
  static double get maxContentWidth => min(_screenWidth, 600.0);
}
