import 'dart:async';
import 'dart:math' as math;

/// Canonical WP-21 budgets derived from ARCHITECTURE.md §29.
abstract final class PerformanceBudgets {
  static const warmInteractive = Duration(seconds: 2);
  static const webInteractive = Duration(seconds: 4);
  static const frame60Hz = Duration(microseconds: 16667);
  static const seedParseValidation = Duration(milliseconds: 300);
  static const queueFilterSort = Duration(milliseconds: 150);
  static const mapProjection = Duration(milliseconds: 250);
  static const queueDebounce = Duration(milliseconds: 250);
  static const maxSnapshotBytes = 3 * 1024 * 1024;
  static const aiManualFallback = Duration(seconds: 4);
}

enum PerformanceMetric {
  coldStart,
  warmStart,
  routeTransition,
  queueFilterSort,
  mapProjection,
  jsonParseValidation,
  aiLatency,
}

final class BenchmarkSample {
  const BenchmarkSample({
    required this.metric,
    required this.elapsed,
    required this.budget,
    this.itemCount,
    this.note,
  });

  final PerformanceMetric metric;
  final Duration elapsed;
  final Duration budget;
  final int? itemCount;
  final String? note;

  bool get withinBudget => elapsed <= budget;

  Map<String, Object?> toJson() => {
    'metric': metric.name,
    'elapsedMicros': elapsed.inMicroseconds,
    'budgetMicros': budget.inMicroseconds,
    'withinBudget': withinBudget,
    if (itemCount != null) 'itemCount': itemCount,
    if (note != null) 'note': note,
  };
}

final class PerformanceProbe {
  const PerformanceProbe();

  Future<BenchmarkSample> measureAsync({
    required PerformanceMetric metric,
    required Duration budget,
    required Future<void> Function() operation,
    int? itemCount,
    String? note,
  }) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return BenchmarkSample(
      metric: metric,
      elapsed: stopwatch.elapsed,
      budget: budget,
      itemCount: itemCount,
      note: note,
    );
  }

  BenchmarkSample measureSync({
    required PerformanceMetric metric,
    required Duration budget,
    required void Function() operation,
    int? itemCount,
    String? note,
  }) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    return BenchmarkSample(
      metric: metric,
      elapsed: stopwatch.elapsed,
      budget: budget,
      itemCount: itemCount,
      note: note,
    );
  }
}

enum ConnectivityState { online, flapping, offline }

enum OfflineSurfaceMode {
  data,
  refreshingWithData,
  offlineWithCache,
  recoverableError,
  blockingError,
}

final class OfflineStateDecision {
  const OfflineStateDecision({
    required this.mode,
    required this.allowRead,
    required this.allowCitizenDraft,
    required this.allowStaffMutation,
  });

  final OfflineSurfaceMode mode;
  final bool allowRead;
  final bool allowCitizenDraft;
  final bool allowStaffMutation;
}

abstract final class OfflineStatePolicy {
  static OfflineStateDecision decide({
    required bool hasSnapshot,
    required bool online,
    required bool refreshing,
    required bool recoverableFailure,
  }) {
    if (!online && hasSnapshot) {
      return const OfflineStateDecision(
        mode: OfflineSurfaceMode.offlineWithCache,
        allowRead: true,
        allowCitizenDraft: true,
        allowStaffMutation: false,
      );
    }
    if (!online && !hasSnapshot) {
      return OfflineStateDecision(
        mode: recoverableFailure
            ? OfflineSurfaceMode.recoverableError
            : OfflineSurfaceMode.blockingError,
        allowRead: false,
        allowCitizenDraft: true,
        allowStaffMutation: false,
      );
    }
    if (refreshing && hasSnapshot) {
      return const OfflineStateDecision(
        mode: OfflineSurfaceMode.refreshingWithData,
        allowRead: true,
        allowCitizenDraft: true,
        allowStaffMutation: true,
      );
    }
    return const OfflineStateDecision(
      mode: OfflineSurfaceMode.data,
      allowRead: true,
      allowCitizenDraft: true,
      allowStaffMutation: true,
    );
  }
}

enum ChaosFailureKind {
  timeout,
  rateLimited,
  malformedJson,
  serverUnavailable,
  connectionReset,
}

/// Retry policy is used for idempotent reads/reconnects and for mutation
/// transports only when the exact same stable clientMutationId is reused.
/// Callers must never synthesize a new mutation id during a transport retry.
final class ResilienceRetryPolicy {
  const ResilienceRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 180),
    this.maxDelay = const Duration(seconds: 2),
    this.jitterRatio = 0.2,
  }) : assert(maxAttempts >= 1),
       assert(jitterRatio >= 0 && jitterRatio <= 1);

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterRatio;

  Duration delayForAttempt(int attempt, {int jitterSeed = 0}) {
    if (attempt <= 0) return Duration.zero;
    final exponent = math.min(attempt - 1, 8);
    final rawMicros = baseDelay.inMicroseconds * (1 << exponent);
    final boundedMicros = math.min(rawMicros, maxDelay.inMicroseconds);
    if (jitterRatio == 0) return Duration(microseconds: boundedMicros);
    final deterministic = ((jitterSeed * 1103515245 + attempt * 12345) & 0x7fffffff) /
        0x7fffffff;
    final signed = (deterministic * 2) - 1;
    final factor = 1 + signed * jitterRatio;
    return Duration(microseconds: math.max(0, (boundedMicros * factor).round()));
  }

  bool shouldRetryStatus(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;
}

typedef Delay = Future<void> Function(Duration duration);

Future<T> retryIdempotent<T>({
  required Future<T> Function(int attempt) operation,
  required bool Function(Object error) shouldRetry,
  ResilienceRetryPolicy policy = const ResilienceRetryPolicy(),
  Delay delay = _defaultDelay,
  int jitterSeed = 0,
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
    try {
      return await operation(attempt);
    } on Object catch (error, stackTrace) {
      lastError = error;
      lastStack = stackTrace;
      if (attempt >= policy.maxAttempts || !shouldRetry(error)) rethrow;
      await delay(policy.delayForAttempt(attempt, jitterSeed: jitterSeed));
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack!);
}

Future<void> _defaultDelay(Duration duration) => Future<void>.delayed(duration);
