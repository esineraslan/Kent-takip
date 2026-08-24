#!/usr/bin/env python3
"""SDK-independent regression gate for the 2026-08-19 map/auth/sidebar hotfix."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def req(path: str, tokens: list[str]) -> str:
    target = ROOT / path
    if not target.is_file():
        raise SystemExit(f'FAIL: missing {path}')
    text = target.read_text(encoding='utf-8-sig')
    for token in tokens:
        if token not in text:
            raise SystemExit(f'FAIL: {path} missing marker {token}')
    return text

pub = req('apps/kent_takip_app/pubspec.yaml', ['flutter_map: 8.3.1', 'latlong2: 0.10.1'])
if not re.search(r'^version:\s*0\.2\.0-rc\.2\+1\s*$', pub, re.M):
    raise SystemExit('FAIL: hotfix app version is not 0.2.0-rc.2+1')

map_source = req('apps/kent_takip_app/lib/src/ui/map/map_experience.dart', [
    "FlutterMap(",
    "MapController()",
    "InteractiveFlag.all",
    "onSubmitted: _submitSearch",
    "_focusPlace(exact)",
    "id: 'search-focus'",
    "ValueKey('map-zoom-in')",
    "ValueKey('map-zoom-out')",
    "onViewportSettled: _onViewportSettled",
])
if 'NeverScrollableScrollPhysics' in map_source:
    raise SystemExit('FAIL: legacy non-scrollable static map grid is still present')

sidebar = req('apps/kent_takip_app/lib/src/ui/shells/staff_shell.dart', [
    "ValueKey('staff-navigation-scroll')",
    'Expanded(',
    'Scrollbar(',
    'ListView(',
    'height: 48',
])

auth = req('apps/kent_takip_app/lib/src/ui/screens/auth_screens.dart', [])
if '_DemoCodeNotice' in auth or "text('u0655')" in auth or "format('u0655'" in auth:
    raise SystemExit('FAIL: fixed demo code is still rendered by auth UI')

req('apps/kent_takip_app/test/map_auth_sidebar_regression_test.dart', [
    'interactive-city-map',
    'Sancaktepe',
    "find.textContaining('Demo kodu:')",
    'staff-navigation-scroll',
    "find.text('KVKK')",
    "find.text('Ayarlar')",
])
req('docs/HOTFIX_2026-08-19_MAP_AUTH_SIDEBAR.md', [])
print('2026-08-19 map/auth/sidebar hotfix source gate passed.')
