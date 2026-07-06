import 'package:flutter/material.dart';

/// Screens narrower than this keep the exact mobile layout untouched.
const double kWebBreakpoint = 768;

/// Screens at or above this width get a persistent navigation sidebar
/// instead of a drawer (see [ResponsiveScaffold]).
const double kDesktopBreakpoint = 1024;

/// Whether the app should render its web/desktop layout, based on the
/// *real* (pre-ScreenUtil-clamp) window width captured once at the app root.
///
/// Read this instead of comparing [MediaQuery] width directly inside screens:
/// the app root clamps the [MediaQuery] size that flutter_screenutil sees
/// (so `.w`/`.h`/`.sp`/`.r` keep mobile-like proportions on wide windows),
/// which means by the time a screen builds, `MediaQuery.sizeOf` no longer
/// reflects the real window width.
class WebLayoutScope extends InheritedWidget {
  final bool isWebLayout;

  /// The real (pre-ScreenUtil-clamp) window width, for widgets that need
  /// finer-grained breakpoints than the mobile/web split (e.g. [kDesktopBreakpoint]).
  final double width;

  const WebLayoutScope({
    super.key,
    required this.isWebLayout,
    required this.width,
    required super.child,
  });

  static bool of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WebLayoutScope>();
    return scope?.isWebLayout ?? false;
  }

  /// The real window width, or a mobile-sized fallback if no scope is found
  /// (e.g. in widget tests that don't wrap with [WebLayoutScope]).
  static double widthOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WebLayoutScope>();
    return scope?.width ?? kWebBreakpoint - 1;
  }

  @override
  bool updateShouldNotify(WebLayoutScope oldWidget) =>
      isWebLayout != oldWidget.isWebLayout || width != oldWidget.width;
}

/// Scales a grid's column count up from [base] (its mobile column count) as
/// the *local* available width grows — pass the width from a [LayoutBuilder]
/// wrapped directly around the grid, so it already reflects any [ResponsiveCenter]
/// cap applied above it.
int responsiveGridColumns(double width, {required int base}) {
  if (width >= 1600) return base + 3;
  if (width >= kDesktopBreakpoint) return base + 2;
  if (width >= kWebBreakpoint) return base + 1;
  return base;
}

/// Centers [child] and caps its width once the viewport is wider than
/// [kWebBreakpoint] (i.e. on web/desktop), so content doesn't stretch across
/// the full browser window. Below the breakpoint it returns [child] as-is,
/// so mobile (and narrow web) rendering is unaffected.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? webPadding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.webPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!WebLayoutScope.of(context)) return child;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    return Center(
      child: webPadding != null ? Padding(padding: webPadding!, child: content) : content,
    );
  }
}
