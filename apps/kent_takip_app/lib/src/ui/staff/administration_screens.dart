import 'dart:async';
import 'package:kent_takip_app/src/localization/app_strings.dart';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:flutter/services.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class DataSourcesScreen extends StatelessWidget {
  DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null) return LoadingView();
    final principal = context.watch<SessionController>().principal;
    if (principal == null) return SizedBox.shrink();
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0117'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0118'),
        ),
        SizedBox(height: KtSpacing.x4),
        Wrap(
          spacing: KtSpacing.x2,
          runSpacing: KtSpacing.x2,
          children: [
            FilledButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => unawaited(controller.sourceOperation(
                        actorId: principal.account.id,
                        action: SourceOperationAction.refreshGtfsSchema,
                      )),
              icon: Icon(Icons.route_outlined),
              label: Text(context.strings.text('u0119')),
            ),
            OutlinedButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => unawaited(_manualIncident(context, controller, principal.account.id)),
              icon: Icon(Icons.add_location_alt_outlined),
              label: Text(context.strings.text('u0120')),
            ),
            OutlinedButton.icon(
              onPressed: controller.busy || snapshot.payload.reports.isEmpty
                  ? null
                  : () => unawaited(controller.sourceOperation(
                        actorId: principal.account.id,
                        action: SourceOperationAction.sync153Mock,
                        payload: {
                          'externalApplicationId': '153-DEMO-${snapshot.revision + 1}',
                          'statusSync': 'received_simulated',
                          'linkedReportId': snapshot.payload.reports.first.id,
                        },
                      )),
              icon: Icon(Icons.sync_alt_rounded),
              label: Text(context.strings.text('u0121')),
            ),
            OutlinedButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => unawaited(_importFixture(context, controller, principal.account.id)),
              icon: Icon(Icons.upload_file_outlined),
              label: Text(context.strings.text('u0122')),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(_copyExport(context, SourceFixtureExport.toJson(snapshot.payload.sourceRecords), 'JSON')),
              icon: Icon(Icons.download_outlined),
              label: Text(context.strings.text('u0123')),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(_copyExport(context, SourceFixtureExport.toCsv(snapshot.payload.sourceRecords), 'CSV')),
              icon: Icon(Icons.table_view_outlined),
              label: Text(context.strings.text('u0124')),
            ),
          ],
        ),
        SizedBox(height: KtSpacing.x4),
        KtBanner(
          title: context.strings.text('u0299'),
          message: context.strings.text('u0451'),
          tone: KtBannerTone.info,
        ),
        SizedBox(height: KtSpacing.x4),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(context.strings.text('u0125'))),
                DataColumn(label: Text(context.strings.text('u0126'))),
                DataColumn(label: Text(context.strings.text('u0127'))),
                DataColumn(label: Text(context.strings.text('u0128'))),
                DataColumn(label: Text(context.strings.text('u0129'))),
                DataColumn(label: Text(context.strings.text('u0130'))),
                DataColumn(label: Text(context.strings.text('u0131'))),
                DataColumn(label: Text(context.strings.text('u0132'))),
                DataColumn(label: Text(context.strings.text('u0133'))),
              ],
              rows: [
                for (final source in SourceCatalog.entries)
                  _sourceRow(context, controller, principal.account.id, snapshot, source),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _sourceRow(
    BuildContext context,
    SnapshotController controller,
    String actorId,
    AppSnapshotDto snapshot,
    SourceCatalogEntry source,
  ) {
    OpaqueEntityDto? health;
    for (final item in snapshot.payload.dataSourceHealth) {
      if (item.body['sourceId'] == source.id || item.id == 'health_${source.id}') health = item;
    }
    final sourceRecords = snapshot.payload.sourceRecords
        .where((item) => item.body['sourceId'] == source.id)
        .toList(growable: false);
    sourceRecords.sort((a, b) => _date(b.body['ingestedAt']).compareTo(_date(a.body['ingestedAt'])));
    final latestIngested = sourceRecords.isEmpty ? null : sourceRecords.first.body['ingestedAt']?.toString();
    final healthWire = health?.body['health']?.toString() ?? (source.enabled ? 'unavailable' : 'disabled');
    final status = switch (healthWire) {
      'fresh' => context.strings.text('u0593'),
      'stale' => context.strings.text('u0594'),
      'quarantined' => context.strings.text('u0595'),
      'disabled' => context.strings.text('u0596'),
      _ => context.strings.text('u0597'),
    };
    return DataRow(cells: [
      DataCell(SizedBox(width: 180, child: Text(source.label))),
      DataCell(Text('${source.kind}\n${source.integrationLabel}')),
      DataCell(_statusChip(status, healthWire)),
      DataCell(Text(_text(health?.body['lastSuccessAt']))),
      DataCell(Text(_text(health?.body['sourceTimestamp']))),
      DataCell(Text(_text(latestIngested))),
      DataCell(Text('${health?.body['acceptedCount'] ?? 0} / ${health?.body['quarantinedCount'] ?? 0}')),
      DataCell(Text(_text(health?.body['lastErrorCode']))),
      DataCell(
        source.enabled && source.id.endsWith('_fixture')
            ? IconButton(
                tooltip: context.strings.text('u0298'),
                onPressed: controller.busy
                    ? null
                    : () => unawaited(controller.sourceOperation(
                          actorId: actorId,
                          action: SourceOperationAction.refreshFixture,
                          payload: {'sourceId': source.id},
                        )),
                icon: Icon(Icons.refresh_rounded),
              )
            : SizedBox(width: 40),
      ),
    ]);
  }

  Future<void> _copyExport(BuildContext context, String content, String format) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.format('u0360', {'format': format}))));
  }

  Future<void> _importFixture(BuildContext context, SnapshotController controller, String actorId) async {
    var format = 'json';
    final content = TextEditingController(
      text: '[{"externalId":"staff-demo-001","sourceUpdatedAt":"2026-08-17T13:00:00.000Z","category":"traffic","label":"Yetkili demo import"}]',
    );
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.text('u0134')),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: format,
                  decoration: InputDecoration(labelText: context.strings.text('u0292')),
                  items: [
                    DropdownMenuItem(value: 'json', child: Text(context.strings.text('u0135'))),
                    DropdownMenuItem(value: 'csv', child: Text(context.strings.text('u0136'))),
                  ],
                  onChanged: (value) => setState(() => format = value ?? format),
                ),
                SizedBox(height: KtSpacing.x3),
                TextField(
                  controller: content,
                  minLines: 6,
                  maxLines: 12,
                  decoration: InputDecoration(labelText: context.strings.text('u0293')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0137'))),
          ],
        ),
      ),
    );
    final value = content.text.trim();
    content.dispose();
    if (approved != true || value.isEmpty) return;
    await controller.sourceOperation(
      actorId: actorId,
      action: SourceOperationAction.importFixture,
      payload: {'format': format, 'content': value},
    );
  }

  Future<void> _manualIncident(BuildContext context, SnapshotController controller, String actorId) async {
    final reason = TextEditingController(text: context.strings.text('u0598'));
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0120')),
        content: TextField(controller: reason, decoration: InputDecoration(labelText: context.strings.text('u0294')), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0138'))),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (approved != true || value.isEmpty) return;
    await controller.sourceOperation(
      actorId: actorId,
      action: SourceOperationAction.manualActiveIncident,
      payload: {
        'category': 'road_surface_damage',
        'unitId': 'unit_road_maintenance',
        'reason': value,
        'latitude': 41.0082,
        'longitude': 28.9784,
      },
    );
  }
}

final class StaffUsersScreen extends StatelessWidget {
  StaffUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    final principal = context.watch<SessionController>().principal;
    if (snapshot == null) return LoadingView();
    if (principal == null) return SizedBox.shrink();
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0139'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0140')),
        SizedBox(height: KtSpacing.x4),
        _RoleMatrixCard(),
        SizedBox(height: KtSpacing.x4),
        Card(
          child: Column(
            children: [
              for (final account in snapshot.payload.accounts) ...[
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(account.id),
                  subtitle: Text(context.strings.format('u0361', {'role': _roleLabel(context, account.role), 'count': account.permissions.length, 'unit': account.unitId == null ? '' : ' · ${account.unitId}'})),
                  trailing: account.id == 'usr_supervisor_demo_001'
                      ? KtStatusChip(label: context.strings.text('u0452'), icon: Icons.verified_outlined, tone: KtStatusTone.info)
                      : PopupMenuButton<String>(
                          enabled: !controller.busy,
                          onSelected: (action) {
                            if (action == 'role') {
                              unawaited(_editRole(context, controller, principal.account.id, account));
                            } else if (action == 'restrict') {
                              unawaited(_restrict(context, controller, principal.account.id, snapshot, account));
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'role', child: Text(context.strings.text('u0141'))),
                            PopupMenuItem(value: 'restrict', child: Text(context.strings.text('u0142'))),
                          ],
                        ),
                ),
                if (account != snapshot.payload.accounts.last) Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _restrict(
    BuildContext context,
    SnapshotController controller,
    String actorId,
    AppSnapshotDto snapshot,
    AccountDto account,
  ) async {
    RestrictionLevel? previous;
    for (final item in snapshot.payload.restrictions.reversed) {
      if (item.body['accountId'] != account.id) continue;
      final raw = item.body['level']?.toString();
      for (final value in RestrictionLevel.values) {
        if (value.name == raw) {
          previous = value;
          break;
        }
      }
      if (previous != null) break;
    }
    final candidateIndex = previous == null ? 0 : RestrictionLevel.values.indexOf(previous) + 1;
    final nextIndex = candidateIndex >= RestrictionLevel.values.length
        ? RestrictionLevel.values.length - 1
        : candidateIndex;
    final next = RestrictionLevel.values[nextIndex];
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0142')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.strings.format('u0362', {'account': account.id, 'level': next.name})),
            SizedBox(height: KtSpacing.x3),
            TextField(controller: reason, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: context.strings.text('u0295'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0143'))),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true || text.isEmpty) return;
    await controller.administration(
      actorId: actorId,
      action: AdministrationAction.decideRestriction,
      payload: {
        'accountId': account.id,
        'level': enumWire(next),
        'reason': text,
        'confirmedByHuman': true,
      },
    );
  }

  Future<void> _editRole(BuildContext context, SnapshotController controller, String actorId, AccountDto account) async {
    var role = account.role;
    final chosen = await showDialog<UserRole>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.strings.format('u0363', {'account': account.id})),
          content: DropdownButtonFormField<UserRole>(
            initialValue: role,
            decoration: InputDecoration(labelText: context.strings.text('u0296')),
            items: UserRole.values
                .where((item) => item != UserRole.demoSupervisor)
                .map((item) => DropdownMenuItem(value: item, child: Text(_roleLabel(context, item))))
                .toList(growable: false),
            onChanged: (value) => setState(() => role = value ?? role),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.strings.text('u0043'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, role), child: Text(context.strings.text('u0144'))),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0145')),
        content: Text(context.strings.format('u0364', {'account': account.id, 'role': _roleLabel(context, chosen)})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0103'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.administration(
      actorId: actorId,
      action: AdministrationAction.updateUserAccess,
      payload: {
        'accountId': account.id,
        'role': enumWire(chosen),
        'unitId': chosen == UserRole.unitOfficer ? (account.unitId ?? 'unit_road_maintenance') : null,
        'permissions': RolePermissionMatrix.permissionsFor(chosen).map(enumWire).toList(growable: false),
        'secondConfirmation': true,
      },
    );
  }
}

final class AuditExplorerScreen extends StatefulWidget {
  AuditExplorerScreen({super.key});

  @override
  State<AuditExplorerScreen> createState() => _AuditExplorerScreenState();
}

final class _AuditExplorerScreenState extends State<AuditExplorerScreen> {
  final _query = TextEditingController();
  var _originalOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<SnapshotController>().snapshot;
    if (snapshot == null) return LoadingView();
    final query = _query.text.trim().toLowerCase();
    final events = snapshot.payload.auditEvents.where((event) {
      final action = event.body['action']?.toString() ?? '';
      if (_originalOnly && action != 'original_media_accessed') return false;
      if (query.isEmpty) return true;
      return event.body.values.any((value) => value?.toString().toLowerCase().contains(query) ?? false);
    }).toList(growable: false)
      ..sort((a, b) => _date(b.body['at']).compareTo(_date(a.body['at'])));
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0146'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0147')),
        SizedBox(height: KtSpacing.x4),
        Wrap(
          spacing: KtSpacing.x2,
          runSpacing: KtSpacing.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(prefixIcon: Icon(Icons.search), labelText: context.strings.text('u0297')),
              ),
            ),
            FilterChip(
              selected: _originalOnly,
              onSelected: (value) => setState(() => _originalOnly = value),
              avatar: Icon(Icons.visibility_outlined, size: 18),
              label: Text(context.strings.text('u0110')),
            ),
            OutlinedButton.icon(
              onPressed: () => _copy(context, AuditExport.toCsv(events), 'CSV'),
              icon: Icon(Icons.table_view_outlined),
              label: Text(context.strings.text('u0148')),
            ),
            OutlinedButton.icon(
              onPressed: () => _copy(context, AuditExport.toJson(events), 'JSON'),
              icon: Icon(Icons.data_object_outlined),
              label: Text(context.strings.text('u0149')),
            ),
          ],
        ),
        SizedBox(height: KtSpacing.x4),
        Card(
          child: Column(
            children: [
              for (final event in events.take(300)) ...[
                ListTile(
                  leading: Icon(
                    event.body['action'] == 'original_media_accessed' ? Icons.visibility_outlined : Icons.history_rounded,
                  ),
                  title: Text(event.body['action']?.toString() ?? 'audit'),
                  subtitle: Text(
                    '${_text(event.body['at'])} · ${_text(event.body['actorId'])} · ${context.strings.text('u0660')}: ${_auditRole(event)} · ${_text(event.body['resourceId'])}\n${_text(event.body['reason'])}',
                  ),
                  isThreeLine: true,
                ),
                Divider(height: 1),
              ],
              if (events.isEmpty)
                Padding(padding: EdgeInsets.all(KtSpacing.x6), child: Text(context.strings.text('u0150'))),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String value, String kind) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.format('u0365', {'kind': kind}))));
  }
}

final class PrivacyRequestsScreen extends StatelessWidget {
  PrivacyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    final principal = context.watch<SessionController>().principal;
    if (snapshot == null) return LoadingView();
    if (principal == null) return SizedBox.shrink();
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0151'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0152')),
        SizedBox(height: KtSpacing.x4),
        if (snapshot.payload.privacyRequests.isEmpty)
          Card(child: Padding(padding: EdgeInsets.all(KtSpacing.x6), child: Text(context.strings.text('u0153'))))
        else
          Card(
            child: Column(
              children: [
                for (final request in snapshot.payload.privacyRequests) ...[
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('${_text(request.body['trackingNumber'])} · ${_text(request.body['type'])}'),
                    subtitle: Text('${_text(request.body['ownerId'])} · ${_text(request.body['status'])}\n${_text(request.body['note'])}'),
                    isThreeLine: true,
                    trailing: request.body['status'] == 'received' || request.body['status'] == 'inReview'
                        ? PopupMenuButton<bool>(
                            onSelected: (accepted) => unawaited(controller.administration(
                              actorId: principal.account.id,
                              action: AdministrationAction.resolvePrivacyRequest,
                              payload: {
                                'requestId': request.id,
                                'accepted': accepted,
                                'reason': accepted ? context.strings.text('u0599') : context.strings.text('u0600'),
                              },
                            )),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: true, child: Text(context.strings.text('u0154'))),
                              PopupMenuItem(value: false, child: Text(context.strings.text('u0155'))),
                            ],
                          )
                        : null,
                  ),
                  Divider(height: 1),
                ],
              ],
            ),
          ),
        SizedBox(height: KtSpacing.x6),
        Text(context.strings.text('u0156'), style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: KtSpacing.x2),
        Card(
          child: snapshot.payload.restrictions.isEmpty
              ? Padding(padding: EdgeInsets.all(KtSpacing.x6), child: Text(context.strings.text('u0157')))
              : Column(
                  children: [
                    for (final item in snapshot.payload.restrictions)
                      ListTile(
                        leading: Icon(Icons.gpp_maybe_outlined),
                        title: Text('${_text(item.body['accountId'])} · ${_text(item.body['level'])}'),
                        subtitle: Text('${_text(item.body['reason'])} · ${context.strings.text('u0661')}: ${_text(item.body['appealStatus'])}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

final class _RoleMatrixCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.grid_view_rounded),
        title: Text(context.strings.text('u0158')),
        subtitle: Text(context.strings.text('u0159')),
        children: [
          for (final role in [
            UserRole.reviewer,
            UserRole.unitOfficer,
            UserRole.planner,
            UserRole.systemAdmin,
            UserRole.demoSupervisor,
          ])
            ListTile(
              title: Text(_roleLabel(context, role)),
              subtitle: Text(RolePermissionMatrix.permissionsFor(role).map((item) => item.name).join(' · ')),
            ),
        ],
      ),
    );
  }
}

Widget _statusChip(String label, String raw) {
  final tone = switch (raw) {
    'fresh' => KtStatusTone.success,
    'stale' => KtStatusTone.warning,
    'quarantined' => KtStatusTone.warning,
    'disabled' => KtStatusTone.neutral,
    _ => KtStatusTone.danger,
  };
  return KtStatusChip(label: label, icon: Icons.info_outline, tone: tone);
}

String _text(Object? value) => value == null || value.toString().isEmpty ? '—' : value.toString();
String _auditRole(OpaqueEntityDto event) {
  final direct = event.body['activeRoleContext'];
  if (direct != null) return direct.toString();
  final after = event.body['after'];
  if (after is Map && after['activeRoleContext'] != null) return after['activeRoleContext'].toString();
  return 'legacy/unknown';
}
DateTime _date(Object? value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
String _roleLabel(BuildContext context, UserRole role) => switch (role) {
  UserRole.guest => context.strings.text('u0601'),
  UserRole.citizen => context.strings.text('u0602'),
  UserRole.reviewer => context.strings.text('u0603'),
  UserRole.unitOfficer => context.strings.text('u0604'),
  UserRole.planner => context.strings.text('u0605'),
  UserRole.systemAdmin => context.strings.text('u0606'),
  UserRole.demoSupervisor => context.strings.text('u0607'),
};
