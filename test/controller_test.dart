import 'package:cupertino_native_plus/cupertino_native_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CNSearchBarController', () {
    test('creates controller successfully', () {
      final controller = CNSearchBarController();
      expect(controller, isNotNull);
    });

    test('isExpanded defaults to false', () {
      final controller = CNSearchBarController();
      expect(controller.isExpanded, false);
    });

    test('onExpandChanged callback can be set and cleared', () {
      final controller = CNSearchBarController();
      var called = false;

      controller.onExpandChanged = () => called = true;
      expect(called, false);

      controller.onExpandChanged = null;
    });

    test('expand does not throw when not attached', () async {
      final controller = CNSearchBarController();
      await expectLater(controller.expand(), completes);
    });

    test('collapse does not throw when not attached', () async {
      final controller = CNSearchBarController();
      await expectLater(controller.collapse(), completes);
    });

    test('clear does not throw when not attached', () async {
      final controller = CNSearchBarController();
      await expectLater(controller.clear(), completes);
    });

    test('focus does not throw when not attached', () async {
      final controller = CNSearchBarController();
      await expectLater(controller.focus(), completes);
    });

    test('unfocus does not throw when not attached', () async {
      final controller = CNSearchBarController();
      await expectLater(controller.unfocus(), completes);
    });
  });

  group('CNFloatingIslandController', () {
    test('creates controller successfully', () {
      final controller = CNFloatingIslandController();
      expect(controller, isNotNull);
    });

    test('isExpanded defaults to false', () {
      final controller = CNFloatingIslandController();
      expect(controller.isExpanded, false);
    });

    test('onExpandChanged callback can be set', () {
      final controller = CNFloatingIslandController();
      var called = false;

      controller.onExpandChanged = () => called = true;
      expect(called, false);
    });

    test('expand does not throw when not attached', () async {
      final controller = CNFloatingIslandController();
      await expectLater(controller.expand(), completes);
    });

    test('collapse does not throw when not attached', () async {
      final controller = CNFloatingIslandController();
      await expectLater(controller.collapse(), completes);
    });

    test('toggle does not throw when not attached', () async {
      final controller = CNFloatingIslandController();
      await expectLater(controller.toggle(), completes);
    });
  });

  group('CNSliderController', () {
    test('creates controller successfully', () {
      final controller = CNSliderController();
      expect(controller, isNotNull);
    });

    test('setValue does not throw when not attached', () async {
      final controller = CNSliderController();
      await expectLater(controller.setValue(0.5), completes);
    });

    test('setValue with animation does not throw when not attached', () async {
      final controller = CNSliderController();
      await expectLater(controller.setValue(0.5, animated: true), completes);
    });
  });
}
