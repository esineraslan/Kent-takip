import 'package:kent_takip_domain/src/entities.dart';
import 'package:kent_takip_domain/src/enums.dart';
import 'package:kent_takip_domain/src/failure.dart';

abstract final class AuthorizationPolicy {
  static void requirePermission(UserAccount actor, Permission permission) {
    if (!actor.permissions.contains(permission)) {
      fail(
        FailureCode.unauthorized,
        'Bu işlem için yetkiniz yok.',
        field: permission.name,
      );
    }
  }

  static void requireOwnerOrPermission(
    UserAccount actor,
    CitizenReport report,
    Permission permission,
  ) {
    if (actor.id != report.ownerId && !actor.permissions.contains(permission)) {
      fail(FailureCode.unauthorized, 'Kayıt görünürlüğü reddedildi.');
    }
  }
}

abstract final class ReportTransitionPolicy {
  static const Map<ReportStatus, Set<ReportStatus>> _allowed = {
    ReportStatus.draft: {ReportStatus.received},
    ReportStatus.received: {
      ReportStatus.aiReview,
      ReportStatus.manualReview,
      ReportStatus.ibbReview,
      ReportStatus.criticalReview,
    },
    ReportStatus.aiReview: {
      ReportStatus.ibbReview,
      ReportStatus.manualReview,
      ReportStatus.criticalReview,
    },
    ReportStatus.manualReview: {ReportStatus.ibbReview, ReportStatus.criticalReview},
    ReportStatus.criticalReview: {ReportStatus.ibbReview},
    ReportStatus.ibbReview: {
      ReportStatus.additionalInfoRequired,
      ReportStatus.assignedUnit,
      ReportStatus.merged,
      ReportStatus.outOfScope,
      ReportStatus.rejected,
    },
    ReportStatus.additionalInfoRequired: {ReportStatus.ibbReview},
    ReportStatus.assignedUnit: {ReportStatus.fieldAssigned, ReportStatus.ibbReview},
    ReportStatus.fieldAssigned: {ReportStatus.inProgress, ReportStatus.assignedUnit},
    ReportStatus.inProgress: {ReportStatus.resolved, ReportStatus.assignedUnit},
    ReportStatus.resolved: {},
    ReportStatus.merged: {},
    ReportStatus.outOfScope: {},
    ReportStatus.rejected: {},
  };

  static void requireAllowed(ReportStatus from, ReportStatus to) {
    if (!(_allowed[from]?.contains(to) ?? false)) {
      fail(
        FailureCode.invalidTransition,
        'Report geçişi yasak: ${from.name} → ${to.name}.',
      );
    }
  }
}

abstract final class IncidentTransitionPolicy {
  static const Map<IncidentStatus, Set<IncidentStatus>> _allowed = {
    IncidentStatus.pendingVerification: {IncidentStatus.verifiedActive},
    IncidentStatus.verifiedActive: {IncidentStatus.resolved, IncidentStatus.archived},
    IncidentStatus.resolved: {IncidentStatus.verifiedActive, IncidentStatus.archived},
    IncidentStatus.archived: {},
  };

  static void requireAllowed(IncidentStatus from, IncidentStatus to) {
    if (!(_allowed[from]?.contains(to) ?? false)) {
      fail(
        FailureCode.invalidTransition,
        'Incident geçişi yasak: ${from.name} → ${to.name}.',
      );
    }
  }
}

abstract final class WorkTransitionPolicy {
  static const Map<WorkStatus, Set<WorkStatus>> _allowed = {
    WorkStatus.draft: {WorkStatus.impactReady, WorkStatus.cancelled},
    WorkStatus.impactReady: {WorkStatus.reviewReady, WorkStatus.cancelled},
    WorkStatus.reviewReady: {WorkStatus.publishedPlanned, WorkStatus.cancelled},
    WorkStatus.publishedPlanned: {WorkStatus.active, WorkStatus.cancelled},
    WorkStatus.active: {WorkStatus.completed},
    WorkStatus.completed: {},
    WorkStatus.cancelled: {},
  };

  static void requireAllowed(WorkStatus from, WorkStatus to) {
    if (!(_allowed[from]?.contains(to) ?? false)) {
      fail(
        FailureCode.invalidTransition,
        'Work geçişi yasak: ${from.name} → ${to.name}.',
      );
    }
  }
}

abstract final class ProjectionPolicy {
  static PinKind? reportPinFor(UserAccount viewer, CitizenReport report) {
    if (report.linkedIncidentId != null) {
      return null;
    }
    if (viewer.id == report.ownerId) {
      return PinKind.pendingVerification;
    }
    final staff = viewer.permissions.contains(Permission.viewReviewQueue);
    if (!staff) {
      return null;
    }
    if (report.status == ReportStatus.criticalReview ||
        report.riskLevel == RiskLevel.criticalSignal) {
      return PinKind.criticalReview;
    }
    return PinKind.pendingVerification;
  }

  static PinKind? incidentPinFor(UrbanIncident incident) {
    return incident.status == IncidentStatus.verifiedActive
        ? PinKind.verifiedActive
        : null;
  }

  static PinKind? workPinFor(MunicipalWork work) {
    return switch (work.status) {
      WorkStatus.publishedPlanned => PinKind.publishedPlanned,
      WorkStatus.active => PinKind.verifiedActive,
      _ => null,
    };
  }

  static MediaRef publicMedia(MediaRef media) {
    if (media.privacyStatus != PrivacyStatus.safe || media.publicRef == null) {
      fail(FailureCode.privacy, 'Kamusal medya güvenli değil.');
    }
    return MediaRef(
      id: media.id,
      privacyStatus: media.privacyStatus,
      publicRef: media.publicRef,
      mimeType: media.mimeType,
    );
  }
}

abstract final class MergePolicy {
  static void requireNoCycle(
    String sourceIncidentId,
    String targetIncidentId,
    Map<String, String> parentByIncidentId,
  ) {
    if (sourceIncidentId == targetIncidentId) {
      fail(FailureCode.validation, 'Incident kendisiyle birleştirilemez.');
    }
    final visited = <String>{sourceIncidentId};
    var cursor = targetIncidentId;
    while (true) {
      if (!visited.add(cursor)) {
        fail(FailureCode.validation, 'Döngüsel incident merge engellendi.');
      }
      final next = parentByIncidentId[cursor];
      if (next == null) {
        return;
      }
      cursor = next;
    }
  }
}

abstract final class AiAuthorityPolicy {
  static Never rejectAutomatedStateChange() {
    fail(
      FailureCode.unauthorized,
      'AI sonucu tek başına domain state değiştiremez.',
    );
  }
}

abstract final class SourceAuthorityPolicy {
  static SourceAuthority preferred(
    SourceAuthority left,
    SourceAuthority right,
  ) {
    if (left.rank.index == right.rank.index) {
      return left.id.compareTo(right.id) <= 0 ? left : right;
    }
    return left.rank.index < right.rank.index ? left : right;
  }

  static void requireOfficialAlertAuthority(SourceAuthority authority) {
    if (!authority.officialAlertAuthority) {
      fail(
        FailureCode.unauthorized,
        'Bu kaynak resmî uyarı yayımlama otoritesine sahip değil.',
      );
    }
  }
}
