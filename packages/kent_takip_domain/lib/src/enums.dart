enum UserRole {
  guest,
  citizen,
  reviewer,
  unitOfficer,
  planner,
  systemAdmin,
  demoSupervisor,
}

enum Permission {
  viewPublicMap,
  submitReport,
  viewOwnReport,
  viewReviewQueue,
  viewOriginalMedia,
  reviewReport,
  routeReport,
  mergeReport,
  manageFieldWork,
  manageMunicipalWork,
  manageSources,
  manageUsers,
  viewAudit,
  managePrivacyRequests,
  resetDemo,
}

enum ReportStatus {
  draft,
  received,
  aiReview,
  ibbReview,
  criticalReview,
  manualReview,
  additionalInfoRequired,
  assignedUnit,
  fieldAssigned,
  inProgress,
  resolved,
  merged,
  outOfScope,
  rejected,
}

enum IncidentStatus { pendingVerification, verifiedActive, resolved, archived }

enum WorkStatus {
  draft,
  impactReady,
  reviewReady,
  publishedPlanned,
  active,
  completed,
  cancelled,
}

enum RiskLevel { low, medium, high, criticalSignal, unknown }

enum PrivacyStatus {
  pending,
  processing,
  safe,
  manualReviewRequired,
  failed,
}

enum AiAnalysisStatus { complete, partial, unavailable, timeout, invalidResponse }

enum CorroborationKind { stillPresent, noLongerVisible, differentLocation }

enum SourceAuthorityRank {
  owningAuthority,
  ibbApproved,
  licensedOpenData,
  thirdPartyUnverified,
  citizenSignal,
  aiSuggestion,
}

enum SourceHealth { fresh, stale, unavailable, quarantined }

enum NotificationType {
  reportReceived,
  statusChanged,
  additionalInfoRequested,
  resolutionPublished,
}

enum PrivacyRequestType {
  access,
  correction,
  deletion,
  automatedAssessmentObjection,
}

enum PrivacyRequestStatus { received, inReview, resolved, rejected }

enum RestrictionLevel { warning, extraVerification, slowed, temporaryRestriction }

enum PinKind { verifiedActive, publishedPlanned, pendingVerification, criticalReview }

