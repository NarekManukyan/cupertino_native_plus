import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../channel/params.dart';

/// Builds a [UiKitView] on iOS or [AppKitView] on macOS with shared codec and pattern.
///
/// Use this to avoid duplicating the platform ternary and [creationParamsCodec]
/// across components.
///
/// Pass [key] to preserve the platform view across rebuilds and avoid jank
/// when the same view is rebuilt with unchanged [creationParams].
Widget buildCupertinoPlatformView(
  BuildContext context, {
  Key? key,
  required String viewType,
  required Map<String, dynamic> creationParams,
  void Function(int id)? onPlatformViewCreated,
  Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return UiKitView(
      key: key,
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: gestureRecognizers,
    );
  }
  return AppKitView(
    key: key,
    viewType: viewType,
    creationParams: creationParams,
    creationParamsCodec: creationParamsCodec,
    onPlatformViewCreated: onPlatformViewCreated,
    gestureRecognizers: gestureRecognizers,
  );
}
