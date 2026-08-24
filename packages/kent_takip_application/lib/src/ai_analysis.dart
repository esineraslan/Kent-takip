import 'dart:async';

import 'package:kent_takip_application/src/security_hardening.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum AiCapability { category, unitRouting, privacy, duplicateDetection, riskSignal }

enum AiPrivacyResult { safe, manualReviewRequired, failed, unavailable }

final class AiCategorySuggestion {
  const AiCategorySuggestion({
    required this.category,
    required this.unitId,
    required this.confidence,
  });

  final String category;
  final String unitId;
  final int confidence;
}

final class AiDuplicateCandidate {
  const AiDuplicateCandidate({
    required this.incidentId,
    required this.confidence,
    required this.distanceMeters,
  });

  final String incidentId;
  final int confidence;
  final int distanceMeters;
}

final class AiAnalysisInput {
  AiAnalysisInput({
    required this.description,
    required this.categoryHint,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.mediaId,
  }) {
    requireText(description, 'description');
    requireText(categoryHint, 'categoryHint');
    GeoPoint(latitude: latitude, longitude: longitude);
    requireUtc(capturedAt, 'capturedAt');
  }

  final String description;
  final String categoryHint;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final String? mediaId;

  JsonMap toJson() => {
    'description': description,
    'categoryHint': categoryHint,
    'location': {'latitude': latitude, 'longitude': longitude},
    'capturedAt': capturedAt.toIso8601String(),
    'mediaId': mediaId,
  };
}

final class AiAnalysisResult {
  AiAnalysisResult({
    required this.status,
    required Iterable<AiCapability> capabilities,
    required Iterable<AiCategorySuggestion> suggestions,
    required this.privacy,
    required Iterable<AiDuplicateCandidate> duplicateCandidates,
    required Iterable<String> reasonCodes,
    required this.riskLevel,
    required this.modelVersion,
    required this.configVersion,
    required this.latency,
  }) : capabilities = List.unmodifiable(capabilities),
       suggestions = List.unmodifiable(suggestions),
       duplicateCandidates = List.unmodifiable(duplicateCandidates),
       reasonCodes = List.unmodifiable(reasonCodes) {
    if (suggestions.length > 3) {
      fail(FailureCode.validation, 'AI en fazla üç kategori önerebilir.');
    }
    for (final item in suggestions) {
      requireScore(item.confidence, 'suggestion.confidence');
    }
    for (final item in duplicateCandidates) {
      requireScore(item.confidence, 'duplicate.confidence');
    }
    if (latency.isNegative) {
      fail(FailureCode.validation, 'AI gecikmesi negatif olamaz.');
    }
  }

  final AiAnalysisStatus status;
  final List<AiCapability> capabilities;
  final List<AiCategorySuggestion> suggestions;
  final AiPrivacyResult privacy;
  final List<AiDuplicateCandidate> duplicateCandidates;
  final List<String> reasonCodes;
  final RiskLevel riskLevel;
  final String modelVersion;
  final String configVersion;
  final Duration latency;

  AiAnalysisDto toSnapshotDto({required String id, required DateTime createdAt}) {
    final primary = suggestions.isEmpty ? null : suggestions.first;
    final duplicate = duplicateCandidates.isEmpty ? null : duplicateCandidates.first;
    return AiAnalysisDto(
      id: id,
      status: status,
      categoryConfidence: primary?.confidence,
      duplicateConfidence: duplicate?.confidence,
      reasonCodes: [
        ...reasonCodes,
        if (primary != null) 'category:${primary.category}',
        if (primary != null) 'unit:${primary.unitId}',
        'privacy:${privacy.name}',
        for (final capability in capabilities) 'capability:${capability.name}',
        for (final item in duplicateCandidates) 'duplicate:${item.incidentId}',
      ],
      modelVersion: modelVersion,
      configVersion: configVersion,
      createdAt: createdAt,
    );
  }
}

abstract interface class KentAiAnalysisService {
  Future<AiAnalysisResult> analyze(AiAnalysisInput input);
}

enum DemoAiScenario { success, partial, unavailable, timeout, invalidResponse }

final class DemoAiAnalysisService implements KentAiAnalysisService {
  const DemoAiAnalysisService({this.scenario = DemoAiScenario.success});

  final DemoAiScenario scenario;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisInput input) async {
    if (scenario == DemoAiScenario.timeout) {
      return _unavailable(AiAnalysisStatus.timeout, 'demo_timeout');
    }
    if (scenario == DemoAiScenario.unavailable) {
      return _unavailable(AiAnalysisStatus.unavailable, 'demo_unavailable');
    }
    if (scenario == DemoAiScenario.invalidResponse) {
      return _unavailable(AiAnalysisStatus.invalidResponse, 'demo_invalid_response');
    }
    final category = _category(input);
    final unit = _unit(category);
    final duplicate = _duplicate(input);
    final partial = scenario == DemoAiScenario.partial;
    return AiAnalysisResult(
      status: partial ? AiAnalysisStatus.partial : AiAnalysisStatus.complete,
      capabilities: [
        AiCapability.category,
        AiCapability.unitRouting,
        AiCapability.privacy,
        if (!partial) AiCapability.duplicateDetection,
        AiCapability.riskSignal,
      ],
      suggestions: [
        AiCategorySuggestion(category: category, unitId: unit, confidence: partial ? 64 : 91),
        if (category != 'road_surface_damage')
          const AiCategorySuggestion(
            category: 'road_surface_damage',
            unitId: 'unit_road_maintenance',
            confidence: 33,
          ),
      ],
      privacy: input.mediaId == null
          ? AiPrivacyResult.unavailable
          : AiPrivacyResult.safe,
      duplicateCandidates: partial || duplicate == null ? const [] : [duplicate],
      reasonCodes: [
        'demo_deterministic',
        if (input.mediaId == null) 'photo_absent',
        if (partial) 'duplicate_capability_partial',
        if (const PromptIsolationPolicy().looksLikeInstruction(input.description))
          'untrusted_prompt_like_content_ignored',
      ],
      riskLevel: _risk(input.description),
      modelVersion: 'demo-rules-2026.08',
      configVersion: 'wp10-v1',
      latency: const Duration(milliseconds: 180),
    );
  }

  AiAnalysisResult _unavailable(AiAnalysisStatus status, String reason) {
    return AiAnalysisResult(
      status: status,
      capabilities: const [],
      suggestions: const [],
      privacy: AiPrivacyResult.unavailable,
      duplicateCandidates: const [],
      reasonCodes: [reason],
      riskLevel: RiskLevel.unknown,
      modelVersion: 'demo-rules-2026.08',
      configVersion: 'wp10-v1',
      latency: const Duration(seconds: 4),
    );
  }

  String _category(AiAnalysisInput input) {
    if (input.categoryHint != 'unsure') return input.categoryHint;

    final text = input.description.toLowerCase();
    if (text.contains('ışık') || text.contains('lamba') || text.contains('karanlık')) {
      return 'lighting';
    }
    if (text.contains('su') || text.contains('rögar') || text.contains('kaçak')) {
      return 'water_infrastructure';
    }
    if (text.contains('sinyal') || text.contains('trafik')) return 'traffic_signal';
    if (text.contains('çöp') || text.contains('atık')) return 'waste_cleaning';
    return 'road_surface_damage';
  }

  String _unit(String category) => switch (category) {
    'lighting' => 'unit_lighting',
    'water_infrastructure' => 'unit_water_infrastructure',
    'traffic_signal' => 'unit_traffic_management',
    'waste_cleaning' => 'unit_environment',
    _ => 'unit_road_maintenance',
  };

  RiskLevel _risk(String description) {
    final value = description.toLowerCase();
    if (value.contains('çökme') || value.contains('yangın') || value.contains('tehlike')) {
      return RiskLevel.criticalSignal;
    }
    return RiskLevel.medium;
  }

  AiDuplicateCandidate? _duplicate(AiAnalysisInput input) {
    if (input.latitude > 41.025 && input.latitude < 41.04 &&
        input.longitude > 28.965 && input.longitude < 28.985) {
      return const AiDuplicateCandidate(
        incidentId: 'inc_demo_0001',
        confidence: 82,
        distanceMeters: 120,
      );
    }
    return null;
  }
}

typedef RemoteAiInvoker = Future<JsonMap> Function(JsonMap request);

final class GuardedRemoteAiAnalysisService implements KentAiAnalysisService {
  GuardedRemoteAiAnalysisService({
    required this.enabled,
    required this.invoke,
    this.timeout = const Duration(seconds: 4),
  });

  final bool enabled;
  final RemoteAiInvoker invoke;
  final Duration timeout;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisInput input) async {
    if (!enabled) {
      return const DemoAiAnalysisService(scenario: DemoAiScenario.unavailable)
          .analyze(input);
    }
    try {
      final json = await invoke(const PromptIsolationPolicy().wrapUntrustedInput(input.toJson())).timeout(timeout);
      final suggestions = decodeList(
        json['suggestions'],
        'suggestions',
        (item, path) {
          final value = expectMap(item, path);
          return AiCategorySuggestion(
            category: expectString(value['category'], '$path.category'),
            unitId: expectString(value['unitId'], '$path.unitId'),
            confidence: expectInt(value['confidence'], '$path.confidence'),
          );
        },
      );
      return AiAnalysisResult(
        status: expectEnum(json['status'], 'status', enumValues(AiAnalysisStatus.values)),
        capabilities: decodeList(
          json['capabilities'],
          'capabilities',
          (item, path) => expectEnum(item, path, enumValues(AiCapability.values)),
        ),
        suggestions: suggestions,
        privacy: expectEnum(json['privacy'], 'privacy', enumValues(AiPrivacyResult.values)),
        duplicateCandidates: decodeList(
          json['duplicateCandidates'] ?? const <Object?>[],
          'duplicateCandidates',
          (item, path) {
            final value = expectMap(item, path);
            return AiDuplicateCandidate(
              incidentId: expectString(value['incidentId'], '$path.incidentId'),
              confidence: expectInt(value['confidence'], '$path.confidence'),
              distanceMeters: expectInt(value['distanceMeters'], '$path.distanceMeters'),
            );
          },
        ),
        reasonCodes: decodeList(json['reasonCodes'], 'reasonCodes', expectString),
        riskLevel: expectEnum(json['riskLevel'], 'riskLevel', enumValues(RiskLevel.values)),
        modelVersion: expectString(json['modelVersion'], 'modelVersion'),
        configVersion: expectString(json['configVersion'], 'configVersion'),
        latency: Duration(milliseconds: expectInt(json['latencyMs'], 'latencyMs')),
      );
    } on TimeoutException {
      return const DemoAiAnalysisService(scenario: DemoAiScenario.timeout)
          .analyze(input);
    } on Object {
      return const DemoAiAnalysisService(scenario: DemoAiScenario.invalidResponse)
          .analyze(input);
    }
  }
}

final class CitizenAiProjection {
  const CitizenAiProjection({
    required this.status,
    required this.suggestedCategories,
    required this.privacy,
    required this.hasPossibleDuplicate,
  });

  factory CitizenAiProjection.from(AiAnalysisResult result) => CitizenAiProjection(
    status: result.status,
    suggestedCategories: result.suggestions.map((item) => item.category).toList(growable: false),
    privacy: result.privacy,
    hasPossibleDuplicate: result.duplicateCandidates.isNotEmpty,
  );

  final AiAnalysisStatus status;
  final List<String> suggestedCategories;
  final AiPrivacyResult privacy;
  final bool hasPossibleDuplicate;
}

final class StaffAiProjection {
  const StaffAiProjection(this.result);
  final AiAnalysisResult result;
}
