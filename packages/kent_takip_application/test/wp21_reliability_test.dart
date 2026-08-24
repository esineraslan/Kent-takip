import 'dart:async';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:test/test.dart';

void main() {
  group('WP-21 offline policy', () {
    test('cached shared snapshot remains readable and staff becomes read-only', () {
      final state = OfflineStatePolicy.decide(
        hasSnapshot: true,
        online: false,
        refreshing: false,
        recoverableFailure: true,
      );
      expect(state.mode, OfflineSurfaceMode.offlineWithCache);
      expect(state.allowRead, isTrue);
      expect(state.allowCitizenDraft, isTrue);
      expect(state.allowStaffMutation, isFalse);
    });

    test('no cache is a blocking read state but citizen draft is still allowed', () {
      final state = OfflineStatePolicy.decide(
        hasSnapshot: false,
        online: false,
        refreshing: false,
        recoverableFailure: false,
      );
      expect(state.mode, OfflineSurfaceMode.blockingError);
      expect(state.allowRead, isFalse);
      expect(state.allowCitizenDraft, isTrue);
      expect(state.allowStaffMutation, isFalse);
    });
  });

  group('WP-21 retry policy', () {
    test('idempotent reads recover after transient 429/timeout class failures', () async {
      var calls = 0;
      final delays = <Duration>[];
      final result = await retryIdempotent<String>(
        policy: const ResilienceRetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 10),
          jitterRatio: 0,
        ),
        delay: (duration) async => delays.add(duration),
        shouldRetry: (error) => error is TimeoutException,
        operation: (attempt) async {
          calls += 1;
          if (attempt < 3) throw TimeoutException('synthetic');
          return 'recovered';
        },
      );
      expect(result, 'recovered');
      expect(calls, 3);
      expect(delays, [const Duration(milliseconds: 10), const Duration(milliseconds: 20)]);
    });

    test('non-retryable failures are never hidden by retry', () async {
      var calls = 0;
      await expectLater(
        retryIdempotent<void>(
          delay: (_) async {},
          shouldRetry: (_) => false,
          operation: (_) async {
            calls += 1;
            throw StateError('permanent');
          },
        ),
        throwsStateError,
      );
      expect(calls, 1);
    });

    test('backoff is bounded', () {
      const policy = ResilienceRetryPolicy(
        baseDelay: Duration(milliseconds: 500),
        maxDelay: Duration(seconds: 2),
        jitterRatio: 0,
      );
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 500));
      expect(policy.delayForAttempt(2), const Duration(seconds: 1));
      expect(policy.delayForAttempt(3), const Duration(seconds: 2));
      expect(policy.delayForAttempt(8), const Duration(seconds: 2));
    });
  });
}
