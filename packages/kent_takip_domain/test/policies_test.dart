import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 8);

  CitizenReport report({
    String ownerId = 'owner-001',
    ReportStatus status = ReportStatus.received,
    RiskLevel risk = RiskLevel.medium,
    String? linkedIncidentId,
  }) {
    return CitizenReport(
      id: 'report-001',
      trackingNumber: 'KT-2026-000001',
      ownerId: ownerId,
      status: status,
      category: 'road_surface_damage',
      location: GeoPoint(latitude: 41, longitude: 29),
      createdAt: now,
      updatedAt: now,
      clientMutationId: 'mutation-001',
      mediaIds: const [],
      riskLevel: risk,
      linkedIncidentId: linkedIncidentId,
    );
  }

  UserAccount user(String id, UserRole role, Set<Permission> permissions) {
    return UserAccount(id: id, role: role, permissions: permissions);
  }

  group('report state machine', () {
    test('allows received to manual review', () {
      expect(
        () => ReportTransitionPolicy.requireAllowed(
          ReportStatus.received,
          ReportStatus.manualReview,
        ),
        returnsNormally,
      );
    });

    test('blocks critical review from resolving without human review', () {
      expect(
        () => ReportTransitionPolicy.requireAllowed(
          ReportStatus.criticalReview,
          ReportStatus.resolved,
        ),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.invalidTransition,
          ),
        ),
      );
    });

    test('resolved report requires evidence', () {
      expect(
        () => report(status: ReportStatus.resolved),
        throwsA(isA<DomainFailure>()),
      );
    });

    test('terminal states reject every outgoing transition', () {
      for (final terminal in {
        ReportStatus.resolved,
        ReportStatus.merged,
        ReportStatus.outOfScope,
        ReportStatus.rejected,
      }) {
        for (final target in ReportStatus.values) {
          expect(
            () => ReportTransitionPolicy.requireAllowed(terminal, target),
            throwsA(isA<DomainFailure>()),
            reason: '${terminal.name} -> ${target.name}',
          );
        }
      }
    });
  });

  group('role projections', () {
    test('owner sees pending pin and another citizen does not', () {
      final pending = report();
      final owner = user(
        'owner-001',
        UserRole.citizen,
        {Permission.viewOwnReport},
      );
      final other = user(
        'owner-002',
        UserRole.citizen,
        {Permission.viewOwnReport},
      );

      expect(
        ProjectionPolicy.reportPinFor(owner, pending),
        PinKind.pendingVerification,
      );
      expect(ProjectionPolicy.reportPinFor(other, pending), isNull);
    });

    test('critical signal is orange only for staff', () {
      final critical = report(risk: RiskLevel.criticalSignal);
      final staff = user(
        'staff-001',
        UserRole.reviewer,
        {Permission.viewReviewQueue},
      );
      final otherCitizen = user('owner-002', UserRole.citizen, const {});

      expect(
        ProjectionPolicy.reportPinFor(staff, critical),
        PinKind.criticalReview,
      );
      expect(ProjectionPolicy.reportPinFor(otherCitizen, critical), isNull);
    });

    test('incident ile bağlanan report ikinci bir pending pin üretmez', () {
      final linked = report(
        status: ReportStatus.assignedUnit,
        linkedIncidentId: 'incident-001',
      );
      final owner = user(
        'owner-001',
        UserRole.citizen,
        {Permission.viewOwnReport},
      );

      expect(ProjectionPolicy.reportPinFor(owner, linked), isNull);
    });
  });

  group('privacy and AI invariants', () {
    test('unsafe media cannot have a public reference', () {
      expect(
        () => MediaRef(
          id: 'media-0001',
          privacyStatus: PrivacyStatus.failed,
          originalRef: 'private/original',
          publicRef: 'public/leak',
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.privacy,
          ),
        ),
      );
    });

    test('AI cannot perform a state transition', () {
      expect(
        AiAuthorityPolicy.rejectAutomatedStateChange,
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.unauthorized,
          ),
        ),
      );
    });

    test('authorization fails closed', () {
      final citizen = user('owner-001', UserRole.citizen, const {});
      expect(
        () => AuthorizationPolicy.requirePermission(
          citizen,
          Permission.reviewReport,
        ),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.unauthorized,
          ),
        ),
      );
    });
  });

  group('merge and work rules', () {
    test('rejects direct and indirect merge cycles', () {
      expect(
        () => MergePolicy.requireNoCycle('a', 'a', const {}),
        throwsA(isA<DomainFailure>()),
      );
      expect(
        () => MergePolicy.requireNoCycle('a', 'b', const {'b': 'a'}),
        throwsA(isA<DomainFailure>()),
      );
    });

    test('planned work may activate but draft may not activate', () {
      expect(
        () => WorkTransitionPolicy.requireAllowed(
          WorkStatus.publishedPlanned,
          WorkStatus.active,
        ),
        returnsNormally,
      );
      expect(
        () => WorkTransitionPolicy.requireAllowed(
          WorkStatus.draft,
          WorkStatus.active,
        ),
        throwsA(isA<DomainFailure>()),
      );
    });

    test('incident cannot skip verification', () {
      expect(
        () => IncidentTransitionPolicy.requireAllowed(
          IncidentStatus.pendingVerification,
          IncidentStatus.resolved,
        ),
        throwsA(isA<DomainFailure>()),
      );
    });
  });

  group('wire value standards', () {
    test('tracking number and UUID validators fail closed', () {
      expect(
        requireTrackingNumber('kt-2026-000001', 'tracking'),
        'KT-2026-000001',
      );
      expect(
        requireUuid(
          '018f2d56-7b8c-7c9d-8abc-0123456789ab',
          'id',
        ),
        '018f2d56-7b8c-7c9d-8abc-0123456789ab',
      );
      expect(
        () => requireUuid('demo-1', 'id'),
        throwsA(isA<DomainFailure>()),
      );
    });

    test('domain event requires UTC', () {
      expect(
        () => DomainEvent(
          id: 'event-001',
          type: DomainEventType.reportReceived,
          aggregateId: 'report-001',
          occurredAt: DateTime(2026, 8, 17),
          data: const {},
        ),
        throwsA(isA<DomainFailure>()),
      );
    });
  });

  group('source authority', () {
    test('owning authority outranks citizen signal', () {
      final official = SourceAuthority(
        id: 'source-official',
        displayName: 'Official',
        rank: SourceAuthorityRank.owningAuthority,
        officialAlertAuthority: true,
      );
      final citizen = SourceAuthority(
        id: 'source-citizen',
        displayName: 'Citizen signal',
        rank: SourceAuthorityRank.citizenSignal,
        officialAlertAuthority: false,
      );

      expect(SourceAuthorityPolicy.preferred(citizen, official), official);
      expect(
        () => SourceAuthorityPolicy.requireOfficialAlertAuthority(citizen),
        throwsA(isA<DomainFailure>()),
      );
    });
  });
}
