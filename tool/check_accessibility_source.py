#!/usr/bin/env python3
"""SDK-independent WP-20 accessibility source gate; not a substitute for AT testing."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]

def need(path, token):
    text=(ROOT/path).read_text(encoding='utf-8')
    if token not in text:
        raise SystemExit(f'FAIL: {path} missing {token}')

need('apps/kent_takip_app/lib/src/ui/map/map_experience.dart', 'MapViewMode.accessibleList')
need('apps/kent_takip_app/lib/src/ui/design/accessibility.dart', 'Scrollable.ensureVisible')
need('apps/kent_takip_app/lib/src/ui/design/accessibility.dart', 'FocusTraversalGroup')
need('apps/kent_takip_app/lib/src/ui/design/accessibility.dart', 'liveRegion: true')
need('apps/kent_takip_app/lib/src/ui/design/tokens.dart', 'disableAnimations')
need('apps/kent_takip_app/lib/src/ui/app_theme.dart', 'highContrast')
need('apps/kent_takip_app/lib/src/ui/app_theme.dart', 'materialTapTargetSize')
need('apps/kent_takip_app/lib/src/ui/app_theme.dart', 'Size(48, 48)')
need('apps/kent_takip_app/lib/src/media/image_picker_camera_gateway.dart', 'requestFullMetadata: false')
need('apps/kent_takip_app/lib/src/media/image_picker_camera_gateway.dart', 'retrieveLostData')
need('apps/kent_takip_app/lib/src/ui/report/report_wizard.dart', 'AppLifecycleState.resumed')
print('Accessibility source gate passed: map/list equivalence, focus recovery, live region, reduced motion, high contrast, 48x48 targets and camera resume recovery are wired.')
