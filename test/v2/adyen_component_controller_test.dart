import 'package:adyen_checkout/src/v2/adyen_component_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdyenComponentController', () {
    test('initial state is not ready with null interaction', () {
      final controller = AdyenComponentController();
      expect(controller.isReady, false);
      expect(controller.requiresUserInteraction, isNull);
    });

    test('readiness update notifies listeners once', () {
      final controller = AdyenComponentController();
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      attachAdyenComponentController(controller, () async {});
      markAdyenComponentControllerReady(controller, false);

      expect(controller.isReady, true);
      expect(controller.requiresUserInteraction, false);
      expect(notificationCount, 1);
    });

    test('submit before ready throws StateError', () {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});

      expect(controller.submit, throwsStateError);
    });

    test('submit invokes attached callback exactly once per call', () async {
      final controller = AdyenComponentController();
      var submitCount = 0;
      attachAdyenComponentController(controller, () async {
        submitCount++;
      });
      markAdyenComponentControllerReady(controller, false);

      await controller.submit();
      await controller.submit();

      expect(submitCount, 2);
    });

    test('submit after detach throws StateError', () async {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});
      markAdyenComponentControllerReady(controller, false);
      detachAdyenComponentController(controller);

      expect(controller.submit, throwsStateError);
    });

    test('submit after dispose throws StateError', () async {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});
      markAdyenComponentControllerReady(controller, false);
      controller.dispose();

      expect(controller.submit, throwsStateError);
    });

    test('attaching the same controller to two owners throws StateError', () {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});

      expect(
        () => attachAdyenComponentController(controller, () async {}),
        throwsStateError,
      );
    });

    test('detach does not dispose a merchant-owned controller', () {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});
      detachAdyenComponentController(controller);

      expect(controller.isReady, false);
      expect(controller.requiresUserInteraction, isNull);
      // Disposing a detached controller should not throw.
      expect(controller.dispose, returnsNormally);
    });

    test('marking ready on detached controller does nothing', () {
      final controller = AdyenComponentController();
      attachAdyenComponentController(controller, () async {});
      detachAdyenComponentController(controller);

      markAdyenComponentControllerReady(controller, false);

      expect(controller.isReady, false);
      expect(controller.requiresUserInteraction, isNull);
    });
  });
}
