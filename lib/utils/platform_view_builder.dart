import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../channel/params.dart';

/// Builds a [UiKitView] on iOS or [AppKitView] on macOS with shared codec and pattern.
///
/// Use this to avoid duplicating the platform ternary and [creationParamsCodec]
/// across components.
Widget buildCupertinoPlatformView(
  BuildContext context, {
  required String viewType,
  required Map<String, dynamic> creationParams,
  void Function(int id)? onPlatformViewCreated,
  Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return UiKitView(
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: gestureRecognizers,
    );
  }
  return AppKitView(
    viewType: viewType,
    creationParams: creationParams,
    creationParamsCodec: creationParamsCodec,
    onPlatformViewCreated: onPlatformViewCreated,
    gestureRecognizers: gestureRecognizers,
  );
}
