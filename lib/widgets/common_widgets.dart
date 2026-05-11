import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Reusable toast/snackbar utility
class AppToast {
  static void success(BuildContext context, String message) {
    _show(context, message, AppTheme.success, Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppTheme.danger, Icons.error_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppTheme.info, Icons.info_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    Responsive.init(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: Responsive.icon(22)),
            SizedBox(width: Responsive.w(12)),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white, fontSize: Responsive.sp(14))),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        margin: EdgeInsets.all(Responsive.pad(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: Responsive.pad(20), vertical: Responsive.pad(6)),
      padding: padding ?? EdgeInsets.all(Responsive.pad(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(borderRadius)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }
}

/// Premium Gradient header with curved bottom — responsive
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Responsive.radius(32)),
          bottomRight: Radius.circular(Responsive.radius(32)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.pad(20),
            vertical: Responsive.pad(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBackButton)
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: Responsive.icon(20)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.pad(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.sp(24),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: Responsive.h(4)),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: Responsive.sp(13),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: Responsive.w(16)),
                      trailing!,
                    ],
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.pad(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.icon(72), color: AppTheme.textLight.withOpacity(0.4)),
            SizedBox(height: Responsive.h(16)),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: Responsive.h(8)),
              Text(
                subtitle!,
                style: TextStyle(fontSize: Responsive.sp(14), color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
