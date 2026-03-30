import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../utils/version_detector.dart';
import 'liquid_glass_container.dart';
import '../style/glass_effect.dart';

/// Position for the toast on screen.
enum CNToastPosition {
  /// Show at the top of the screen.
  top,

  /// Show at the center of the screen.
  center,

  /// Show at the bottom of the screen.
  bottom,
}

/// Duration presets for toasts.
enum CNToastDuration {
  /// Short duration (2 seconds).
  short,

  /// Medium duration (3.5 seconds).
  medium,

  /// Long duration (5 seconds).
  long,
}

/// Style presets for toasts.
enum CNToastStyle {
  /// Default toast style.
  normal,

  /// Success toast (green tint).
  success,

  /// Error toast (red tint).
  error,

  /// Warning toast (yellow/orange tint).
  warning,

  /// Info toast (blue tint).
  info,
}

/// A native toast notification widget.
///
/// Toasts are lightweight, non-intrusive notifications that appear briefly
/// and auto-dismiss. Unlike snackbars, they don't require user interaction
/// and are typically positioned in the center or top of the screen.
///
/// On iOS 26+, supports Liquid Glass effects for a native look.
///
/// ## Basic Usage
///
/// ```dart
/// CNToast.show(
///   context: context,
///   message: 'Settings saved',
/// );
/// ```
///
/// ## With Icon
///
/// ```dart
/// CNToast.show(
///   context: context,
///   message: 'Copied to clipboard',
///   icon: Icon(CupertinoIcons.doc_on_clipboard_fill),
/// );
/// ```
///
/// ## Success Toast
///
/// ```dart
/// CNToast.success(
///   context: context,
///   message: 'Profile updated successfully',
/// );
/// ```
///
/// ## Error Toast
///
/// ```dart
/// CNToast.error(
///   context: context,
///   message: 'Failed to save changes',
/// );
/// ```
///
/// ## Custom Position
///
/// ```dart
/// CNToast.show(
///   context: context,
///   message: 'New message',
///   position: CNToastPosition.top,
/// );
/// ```
class CNToast {
  CNToast._();

  static final List<_ActiveToastInfo> _activeToasts = [];

  /// Shows a toast with the given message.
  static void show({
    required BuildContext context,
    required String message,
    Widget? icon,
    CNToastPosition position = CNToastPosition.center,
    CNToastDuration duration = CNToastDuration.medium,
    CNToastStyle style = CNToastStyle.normal,
    Color? backgroundColor,
    Color? textColor,
    bool useGlassEffect = true,
  }) {
    // Push all existing toasts at this position one level deeper.
    for (final t in _activeToasts.where((t) => t.position == position)) {
      t.depthNotifier.value++;
    }

    final depthNotifier = ValueNotifier<int>(0);
    final autoDismissSignal = _Signal();
    final info = _ActiveToastInfo(
      position: position,
      depthNotifier: depthNotifier,
      autoDismissSignal: autoDismissSignal,
    );
    _activeToasts.add(info);

    final overlay = Overlay.of(context);
    final shouldUseGlass =
        PlatformVersion.supportsLiquidGlass && useGlassEffect;

    var dismissed = false;
    late OverlayEntry overlayEntry;

    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      // Shift toasts that were behind this one back up.
      final myDepth = depthNotifier.value;
      _activeToasts.remove(info);
      for (final t in _activeToasts.where(
        (t) => t.position == position && t.depthNotifier.value > myDepth,
      )) {
        t.depthNotifier.value--;
      }
      if (overlayEntry.mounted) overlayEntry.remove();
    }

    overlayEntry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        icon: icon,
        position: position,
        style: style,
        backgroundColor: backgroundColor,
        textColor: textColor,
        useGlassEffect: shouldUseGlass,
        onDismiss: dismiss,
        isLoading: false,
        depthNotifier: depthNotifier,
        autoDismissSignal: autoDismissSignal,
      ),
    );

    overlay.insert(overlayEntry);
    Timer(_getDuration(duration), () {
      if (!dismissed) autoDismissSignal.fire();
    });
  }

  /// Shows a success toast.
  static void success({
    required BuildContext context,
    required String message,
    CNToastPosition position = CNToastPosition.center,
    CNToastDuration duration = CNToastDuration.medium,
    bool useGlassEffect = true,
  }) {
    show(
      context: context,
      message: message,
      icon: const Icon(
        CupertinoIcons.checkmark_circle_fill,
        color: CupertinoColors.systemGreen,
        size: 24,
      ),
      position: position,
      duration: duration,
      style: CNToastStyle.success,
      useGlassEffect: useGlassEffect,
    );
  }

  /// Shows an error toast.
  static void error({
    required BuildContext context,
    required String message,
    CNToastPosition position = CNToastPosition.center,
    CNToastDuration duration = CNToastDuration.medium,
    bool useGlassEffect = true,
  }) {
    show(
      context: context,
      message: message,
      icon: const Icon(
        CupertinoIcons.xmark_circle_fill,
        color: CupertinoColors.systemRed,
        size: 24,
      ),
      position: position,
      duration: duration,
      style: CNToastStyle.error,
      useGlassEffect: useGlassEffect,
    );
  }

  /// Shows a warning toast.
  static void warning({
    required BuildContext context,
    required String message,
    CNToastPosition position = CNToastPosition.center,
    CNToastDuration duration = CNToastDuration.medium,
    bool useGlassEffect = true,
  }) {
    show(
      context: context,
      message: message,
      icon: const Icon(
        CupertinoIcons.exclamationmark_triangle_fill,
        color: CupertinoColors.systemOrange,
        size: 24,
      ),
      position: position,
      duration: duration,
      style: CNToastStyle.warning,
      useGlassEffect: useGlassEffect,
    );
  }

  /// Shows an info toast.
  static void info({
    required BuildContext context,
    required String message,
    CNToastPosition position = CNToastPosition.center,
    CNToastDuration duration = CNToastDuration.medium,
    bool useGlassEffect = true,
  }) {
    show(
      context: context,
      message: message,
      icon: const Icon(
        CupertinoIcons.info_circle_fill,
        color: CupertinoColors.systemBlue,
        size: 24,
      ),
      position: position,
      duration: duration,
      style: CNToastStyle.info,
      useGlassEffect: useGlassEffect,
    );
  }

  /// Shows a loading toast that must be dismissed manually.
  static CNLoadingToastHandle loading({
    required BuildContext context,
    String message = 'Loading...',
    CNToastPosition position = CNToastPosition.center,
    bool useGlassEffect = true,
  }) {
    final handle = CNLoadingToastHandle._();

    final overlay = Overlay.of(context);
    final shouldUseGlass =
        PlatformVersion.supportsLiquidGlass && useGlassEffect;

    handle._overlayEntry = OverlayEntry(
      builder: (context) {
        return _ToastOverlay(
          message: message,
          icon: const CupertinoActivityIndicator(),
          position: position,
          style: CNToastStyle.normal,
          backgroundColor: null,
          textColor: null,
          useGlassEffect: shouldUseGlass,
          onDismiss: () {},
          isLoading: true,
          depthNotifier: ValueNotifier(0),
          autoDismissSignal: _Signal(),
        );
      },
    );

    overlay.insert(handle._overlayEntry!);
    return handle;
  }

  /// Clears all active toasts.
  static void clear() {
    _activeToasts.clear();
  }

  static Duration _getDuration(CNToastDuration duration) {
    switch (duration) {
      case CNToastDuration.short:
        return const Duration(seconds: 2);
      case CNToastDuration.medium:
        return const Duration(milliseconds: 3500);
      case CNToastDuration.long:
        return const Duration(seconds: 5);
    }
  }
}

class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _ActiveToastInfo {
  _ActiveToastInfo({
    required this.position,
    required this.depthNotifier,
    required this.autoDismissSignal,
  });

  final CNToastPosition position;
  final ValueNotifier<int> depthNotifier;
  final _Signal autoDismissSignal;
}

/// Handle for dismissing a loading toast.
class CNLoadingToastHandle {
  CNLoadingToastHandle._();

  OverlayEntry? _overlayEntry;

  /// Dismisses the loading toast.
  void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    this.icon,
    required this.position,
    required this.style,
    this.backgroundColor,
    this.textColor,
    required this.useGlassEffect,
    required this.onDismiss,
    required this.isLoading,
    required this.depthNotifier,
    required this.autoDismissSignal,
  });

  final String message;
  final Widget? icon;
  final CNToastPosition position;
  final CNToastStyle style;
  final Color? backgroundColor;
  final Color? textColor;
  final bool useGlassEffect;
  final VoidCallback onDismiss;
  final bool isLoading;
  final ValueNotifier<int> depthNotifier;
  final _Signal autoDismissSignal;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with TickerProviderStateMixin {
  // Entrance / exit animation.
  late AnimationController _enterController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Depth (card-stack) animation.
  late AnimationController _depthController;
  double _visualDepth = 0;
  double _depthFrom = 0;
  late Animation<double> _depthAnimation;

  // Swipe state.
  double _dragOffset = 0;
  bool _isDismissing = false;
  AnimationController? _swipeController;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    _enterController.forward();

    _depthController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _depthAnimation = Tween<double>(begin: 0, end: 0).animate(_depthController);
    _depthController.addListener(() {
      setState(() => _visualDepth = _depthAnimation.value);
    });

    widget.depthNotifier.addListener(_onDepthChanged);
    widget.autoDismissSignal.addListener(_onAutoDismiss);
  }

  @override
  void dispose() {
    widget.depthNotifier.removeListener(_onDepthChanged);
    widget.autoDismissSignal.removeListener(_onAutoDismiss);
    _swipeController?.dispose();
    _depthController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _onDepthChanged() {
    final target = widget.depthNotifier.value.toDouble();
    _depthFrom = _visualDepth;
    _depthAnimation = Tween<double>(
      begin: _depthFrom,
      end: target,
    ).animate(CurvedAnimation(parent: _depthController, curve: Curves.easeOut));
    _depthController.forward(from: 0);
  }

  void _onAutoDismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _enterController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  // ── Swipe ──────────────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    _swipeController?.stop();
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > 60 || velocity.abs() > 500) {
      _flyOut(velocity);
    } else {
      _snapBack();
    }
  }

  void _flyOut(double velocity) {
    _isDismissing = true;
    _swipeController?.dispose();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    final direction = (_dragOffset != 0 ? _dragOffset : velocity) >= 0 ? 1 : -1;
    final flyTarget = direction * 500.0;
    final flyAnim = Tween<double>(
      begin: _dragOffset,
      end: flyTarget,
    ).animate(CurvedAnimation(parent: _swipeController!, curve: Curves.easeIn));
    _swipeController!.addListener(
      () => setState(() => _dragOffset = flyAnim.value),
    );
    _enterController.reverse();
    _swipeController!.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _snapBack() {
    _swipeController?.dispose();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    final snapAnim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _swipeController!, curve: Curves.elasticOut),
    );
    _swipeController!.addListener(
      () => setState(() => _dragOffset = snapAnim.value),
    );
    _swipeController!.forward();
  }

  // ── Visual helpers ──────────────────────────────────────────────────────────

  // depth 0 = front (newest); depth 1 peeks behind, depth 2+ hidden.
  double get _depthScale => 1.0 - _visualDepth * 0.08;

  double get _depthOpacity =>
      (_visualDepth >= 2 ? 0.0 : 1.0 - _visualDepth * 0.35).clamp(0.0, 1.0);

  // Peek direction: older toasts peek *toward* the screen center.
  double get _depthYOffset {
    switch (widget.position) {
      case CNToastPosition.top:
        return _visualDepth * 10; // peek downward (away from edge)
      case CNToastPosition.center:
        return _visualDepth * 10;
      case CNToastPosition.bottom:
        return -_visualDepth * 10; // peek upward (away from edge)
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    switch (widget.style) {
      case CNToastStyle.normal:
        return isDark ? const Color(0xE6333333) : const Color(0xE6FFFFFF);
      case CNToastStyle.success:
        return isDark ? const Color(0xE6264D26) : const Color(0xE6E8F5E9);
      case CNToastStyle.error:
        return isDark ? const Color(0xE64D2626) : const Color(0xE6FFEBEE);
      case CNToastStyle.warning:
        return isDark ? const Color(0xE64D3D26) : const Color(0xE6FFF3E0);
      case CNToastStyle.info:
        return isDark ? const Color(0xE626444D) : const Color(0xE6E3F2FD);
    }
  }

  Color _getTextColor(BuildContext context) {
    if (widget.textColor != null) return widget.textColor!;
    return CupertinoColors.label.resolveFrom(context);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 12)],
          Flexible(
            child: Text(
              widget.message,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    if (widget.useGlassEffect) {
      content = LiquidGlassContainer(
        config: LiquidGlassConfig(
          effect: CNGlassEffect.regular,
          shape: CNGlassEffectShape.capsule,
          tint: backgroundColor,
        ),
        child: content,
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      );
    }

    final topPadding = MediaQuery.of(context).viewPadding.top;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final dragOpacity = (1.0 - _dragOffset.abs() / 150).clamp(0.0, 1.0);

    // Only the front toast (depth ≈ 0) should receive gestures.
    // Back toasts share the same screen region and would otherwise all fire
    // simultaneously on a single swipe.
    final toast = IgnorePointer(
      ignoring: _visualDepth > 0.3,
      child: GestureDetector(
        onVerticalDragUpdate: widget.isLoading ? null : _onDragUpdate,
        onVerticalDragEnd: widget.isLoading ? null : _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _depthYOffset + _dragOffset),
          child: Transform.scale(
            scale: _depthScale,
            child: Opacity(
              opacity: (_depthOpacity * dragOpacity).clamp(0.0, 1.0),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    switch (widget.position) {
      case CNToastPosition.top:
        return Positioned(
          top: topPadding + 60,
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.topCenter, child: toast),
        );
      case CNToastPosition.center:
        return Positioned.fill(
          child: Align(alignment: Alignment.center, child: toast),
        );
      case CNToastPosition.bottom:
        return Positioned(
          bottom: bottomPadding + 16,
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.bottomCenter, child: toast),
        );
    }
  }
}
