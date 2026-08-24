import 'package:kent_takip_domain/src/entities.dart';

final class DomainSnapshot {
  DomainSnapshot({
    required Iterable<UserAccount> accounts,
    required Iterable<CitizenReport> reports,
    required Iterable<UrbanIncident> incidents,
    required Iterable<MunicipalWork> municipalWorks,
    required Iterable<SourceAuthority> sourceAuthorities,
    required Iterable<SourceRecord> sourceRecords,
    required Iterable<DataSourceHealth> dataSourceHealth,
    required Iterable<MediaRef> media,
    required Iterable<AiAnalysis> analyses,
    required Iterable<CorroborationSignal> corroborations,
    required Iterable<TimelineEvent> timeline,
    required Iterable<AppNotification> notifications,
    required Iterable<AuditEvent> auditEvents,
    required Iterable<PrivacyRequest> privacyRequests,
    required Iterable<AccountRestriction> restrictions,
    required Iterable<DemoScenario> demoScenarios,
  }) : accounts = List<UserAccount>.unmodifiable(accounts),
       reports = List<CitizenReport>.unmodifiable(reports),
       incidents = List<UrbanIncident>.unmodifiable(incidents),
       municipalWorks = List<MunicipalWork>.unmodifiable(municipalWorks),
       sourceAuthorities = List<SourceAuthority>.unmodifiable(sourceAuthorities),
       sourceRecords = List<SourceRecord>.unmodifiable(sourceRecords),
       dataSourceHealth = List<DataSourceHealth>.unmodifiable(dataSourceHealth),
       media = List<MediaRef>.unmodifiable(media),
       analyses = List<AiAnalysis>.unmodifiable(analyses),
       corroborations = List<CorroborationSignal>.unmodifiable(corroborations),
       timeline = List<TimelineEvent>.unmodifiable(timeline),
       notifications = List<AppNotification>.unmodifiable(notifications),
       auditEvents = List<AuditEvent>.unmodifiable(auditEvents),
       privacyRequests = List<PrivacyRequest>.unmodifiable(privacyRequests),
       restrictions = List<AccountRestriction>.unmodifiable(restrictions),
       demoScenarios = List<DemoScenario>.unmodifiable(demoScenarios);

  final List<UserAccount> accounts;
  final List<CitizenReport> reports;
  final List<UrbanIncident> incidents;
  final List<MunicipalWork> municipalWorks;
  final List<SourceAuthority> sourceAuthorities;
  final List<SourceRecord> sourceRecords;
  final List<DataSourceHealth> dataSourceHealth;
  final List<MediaRef> media;
  final List<AiAnalysis> analyses;
  final List<CorroborationSignal> corroborations;
  final List<TimelineEvent> timeline;
  final List<AppNotification> notifications;
  final List<AuditEvent> auditEvents;
  final List<PrivacyRequest> privacyRequests;
  final List<AccountRestriction> restrictions;
  final List<DemoScenario> demoScenarios;
}

