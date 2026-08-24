#!/usr/bin/env python3
"""SDK-independent traceability gate for WP-23 / WP-24."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]

def req(path, tokens):
    p=ROOT/path
    if not p.is_file(): raise SystemExit(f'FAIL: missing {path}')
    t=p.read_text(encoding='utf-8-sig')
    for token in tokens:
        if token not in t: raise SystemExit(f'FAIL: {path} missing marker {token}')
    return t

req('packages/kent_takip_application/lib/src/pilot_analytics.dart',[
    'PilotAnalyticsProjection','RoiCalculator','JuryDemoScenario','PilotGoNoGoPolicy',
    'first_review','staff_override','repeat_status_request','citizen_resolution_feedback'])
req('packages/kent_takip_application/lib/src/source_governance.dart',['simulateOutage','source_demo_outage_enabled','staleCacheRetained'])
req('packages/kent_takip_application/lib/src/commands.dart',['CitizenActionKind.statusRequest','repeat_status_request','citizen_resolution_feedback'])
req('apps/kent_takip_app/lib/src/ui/screens/demo_entry_screens.dart',['JuryDemoScenario.steps','SourceOperationAction.simulateOutage','DemoAiScenario.unavailable','DemoClockControl'])
req('apps/kent_takip_app/lib/src/ui/staff/pilot_analytics_screen.dart',['PilotAnalyticsProjection.calculate','RoiCalculator.calculate'])
req('packages/kent_takip_application/test/wp23_wp24_test.dart',['WP-23 KPI','WP-23 ROI','WP-24 go/no-go'])
for path in [
    'docs/PILOT_BASELINE_TARGET_GONOGO.md','docs/DEMO_RUNBOOK.md','docs/DEMO_REHEARSAL_REPORT.md',
    'docs/RELEASE_MANIFEST.md','docs/FINAL_AUDIT.md','docs/KNOWN_LIMITATIONS.md',
    'docs/work_packages/WP-23_REPORT.md','docs/work_packages/WP-24_REPORT.md','docs/QUALITY_EVIDENCE_WP23_WP24.md']:
    req(path,[])
road=req('ROADMAP.md',['| WP-23 |','| WP-24 |'])
for wp in ('WP-23','WP-24'):
    line=next((x for x in road.splitlines() if x.startswith(f'| {wp} |')),None)
    if not line or 'BLOCKED' not in line:
        raise SystemExit(f'FAIL: {wp} must remain BLOCKED until runtime/build/human gates pass')
pub=req('apps/kent_takip_app/pubspec.yaml',['version:'])
if not re.search(r'^version:\s*0\.2\.0-rc\.2\+1\s*$',pub,re.M):
    raise SystemExit('FAIL: RC version is not frozen to 0.2.0-rc.2+1')
workflow=req('.github/workflows/quality.yml',['WP-23/WP-24 traceability gate','build_release_evidence.py'])
print('WP-23/WP-24 traceability gate passed.')
