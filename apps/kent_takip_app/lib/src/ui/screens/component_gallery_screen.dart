import 'dart:async';
import 'package:kent_takip_app/src/localization/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/design/accessibility.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_app/src/ui/design/responsive.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class ComponentGalleryScreen extends StatefulWidget {
  ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

final class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  var _tab = 0;
  var _selectedPin = 0;
  String? _refreshedKey = 'u0551';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppPaths.demoStart)),
        title: Text(context.strings.text('u0060')),
      ),
      body: KtKeyboardScope(
        onRefresh: () => setState(() => _refreshedKey = 'u0552'),
        child: KtPageBody(
          child: ListView(
            children: [
              KtBanner(
                title: context.strings.text('u0249'),
                message: context.strings.text('u0250'),
              ),
              SizedBox(height: KtSpacing.x6),
              KtLiveRegion(message: context.strings.text(_refreshedKey!), child: Text(context.strings.text(_refreshedKey!))),
              SizedBox(height: KtSpacing.x6),
              _Section(
                title: context.strings.text('u0251'),
                child: Wrap(
                  spacing: KtSpacing.x3,
                  runSpacing: KtSpacing.x3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KtFocusRegion(
                      autofocus: true,
                      child: KtButton(label: context.strings.text('u0409'), onPressed: () {}),
                    ),
                    KtButton(
                      label: context.strings.text('u0410'),
                      onPressed: () {},
                      kind: KtButtonKind.secondary,
                    ),
                    KtButton(
                      label: context.strings.text('u0411'),
                      onPressed: () {},
                      kind: KtButtonKind.danger,
                    ),
                    KtButton(
                      label: context.strings.text('u0412'),
                      kind: KtButtonKind.secondary,
                      onPressed: () => unawaited(
                        showKtDialog<void>(
                          context: context,
                          title: context.strings.text('u0252'),
                          content: Text(context.strings.text('u0061'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(context.strings.text('u0062')),
                            ),
                          ],
                        ),
                      ),
                    ),
                    KtButton(
                      label: context.strings.text('u0413'),
                      kind: KtButtonKind.secondary,
                      onPressed: () => unawaited(
                        showKtSheet<void>(
                          context: context,
                          child: KtCard(
                            child: Text(context.strings.text('u0063'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: KtTextField(
                        label: context.strings.text('u0414'),
                        hint: context.strings.text('u0553'),
                        prefixIcon: Icons.search_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: context.strings.text('u0253'),
                child: Wrap(
                  spacing: KtSpacing.x2,
                  runSpacing: KtSpacing.x2,
                  children: [
                    KtStatusChip(label: context.strings.text('u0037'), icon: Icons.search_rounded),
                    KtStatusChip(
                      label: context.strings.text('u0375'),
                      icon: Icons.check_circle_outline_rounded,
                      tone: KtStatusTone.success,
                    ),
                    KtStatusChip(
                      label: context.strings.text('u0193'),
                      icon: Icons.schedule_rounded,
                      tone: KtStatusTone.warning,
                    ),
                    KtStatusChip(
                      label: context.strings.text('u0415'),
                      icon: Icons.priority_high_rounded,
                      tone: KtStatusTone.danger,
                    ),
                  ],
                ),
              ),
              _Section(
                title: context.strings.text('u0254'),
                child: Wrap(
                  spacing: KtSpacing.x4,
                  runSpacing: KtSpacing.x4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < PinKind.values.length; i++)
                      KtMapPin(
                        kind: PinKind.values[i],
                        category: context.strings.text('u0051'),
                        location: context.strings.text('u0651'),
                        selected: _selectedPin == i,
                        onTap: () => setState(() => _selectedPin = i),
                      ),
                    KtMapCluster(count: 24, location: context.strings.text('u0650'), onTap: () {}),
                  ],
                ),
              ),
              _Section(
                title: context.strings.text('u0255'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KtTabs(
                      labels: [context.strings.text('u0648'), context.strings.text('u0554'), context.strings.text('u0649')],
                      selectedIndex: _tab,
                      onSelected: (value) => setState(() => _tab = value),
                    ),
                    SizedBox(height: KtSpacing.x4),
                    KtQueueRow(
                      title: context.strings.text('u0256'),
                      subtitle: 'KT-2026-08421 · ${context.strings.text('u0650')}',
                      status: context.strings.text('u0555'),
                      statusIcon: Icons.warning_amber_rounded,
                      selected: true,
                      onTap: () {},
                    ),
                    KtTable(
                      columns: [context.strings.text('u0556'), context.strings.text('u0557'), context.strings.text('u0558')],
                      rows: [
                        ['KT-2026-08421', context.strings.text('u0055'), context.strings.text('u0520')],
                        ['KT-2026-08417', context.strings.text('u0056'), context.strings.text('u0559')],
                      ],
                    ),
                  ],
                ),
              ),
              _Section(
                title: context.strings.text('u0027'),
                child: KtTimeline(
                  items: [
                    KtTimelineItem(
                      title: context.strings.text('u0257'),
                      description: context.strings.text('u0416'),
                      at: context.strings.text('u0560'),
                      icon: Icons.check_circle_rounded,
                    ),
                    KtTimelineItem(
                      title: context.strings.text('u0258'),
                      description: context.strings.text('u0417'),
                      at: context.strings.text('u0561'),
                      icon: Icons.route_rounded,
                    ),
                    KtTimelineItem(
                      title: context.strings.text('u0259'),
                      description: context.strings.text('u0562'),
                      at: '—',
                      icon: Icons.radio_button_unchecked_rounded,
                      complete: false,
                    ),
                  ],
                ),
              ),
              _Section(
                title: context.strings.text('u0260'),
                child: SizedBox(
                  height: 300,
                  child: PageView(
                    children: [
                      LoadingView(),
                      EmptyView(
                        title: context.strings.text('u0261'),
                        description: context.strings.text('u0418'),
                      ),
                      OfflineView(onRetry: () {}),
                      RecoverableErrorView(
                        message: context.strings.text('u0262'),
                        onRetry: () {},
                      ),
                      BlockingErrorView(
                        message: context.strings.text('u0263'),
                        reference: 'gallery-example',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: KtSpacing.x8),
      child: KtCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: KtSpacing.x4),
            child,
          ],
        ),
      ),
    );
  }
}
