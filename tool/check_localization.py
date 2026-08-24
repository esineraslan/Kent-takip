#!/usr/bin/env python3
"""SDK-independent WP-20 localization/source-copy gate."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'apps/kent_takip_app/lib/src/localization/app_text_catalog.dart'
UI_ROOT = ROOT / 'apps/kent_takip_app/lib/src/ui'
APP = ROOT / 'apps/kent_takip_app/lib/src/app.dart'


def catalog(name: str) -> dict[str, str]:
    text = CATALOG.read_text(encoding='utf-8')
    marker = f'const Map<String, String> {name} = {{'
    start = text.index(marker) + len(marker)
    end = text.index('\n};', start)
    block = text[start:end]
    pairs = re.findall(r"^\s*'([^']+)'\s*:\s*'((?:\\.|[^'])*)',\s*$", block, re.M)
    return dict(pairs)


def fail(message: str) -> None:
    print(f'FAIL: {message}')
    raise SystemExit(1)


def main() -> None:
    tr = catalog('appTextTr')
    en = catalog('appTextEn')
    if not tr or not en:
        fail('TR/EN catalog could not be parsed')
    if set(tr) != set(en):
        fail(f'catalog key mismatch: TR-only={sorted(set(tr)-set(en))[:8]}, EN-only={sorted(set(en)-set(tr))[:8]}')
    empty = [key for key in tr if not tr[key].strip() or not en[key].strip()]
    if empty:
        fail(f'empty localization values: {empty[:8]}')
    accented_tr = re.compile(r'[çğıöşüÇĞİÖŞÜ]')
    en_with_tr_chars = [key for key, value in en.items() if accented_tr.search(value)]
    if en_with_tr_chars:
        fail(f'English catalog has Turkish-specific characters: {en_with_tr_chars[:8]}')

    sources = [*UI_ROOT.rglob('*.dart'), APP]
    referenced: set[str] = set()
    violations: list[str] = []
    literal_patterns = [
        re.compile(r"\b(?:Text|SelectableText)\(\s*(['\"])([^'\"$]{2,})\1"),
        re.compile(r"\b(?:label|hint|title|message|description|tooltip|semanticLabel|helperText|labelText|hintText|status|locationLabel|sourceLabel)\s*:\s*(['\"])([^'\"$]{2,})\1"),
    ]
    # These are wire/data literals, not copy. The UI may display their values only as
    # developer/demo data where a localized label surrounds them.
    technical = re.compile(r'^(?:—|\d+(?:\.\d+)?|WGS84|UTC ISO-8601|[A-Za-z0-9]+(?:_[A-Za-z0-9_]+)+|(?:https?|media)://\S+)$')
    for path in sources:
        text = path.read_text(encoding='utf-8')
        if 'context.strings.select(' in text:
            for line_no, line in enumerate(text.splitlines(), 1):
                if 'context.strings.select(' in line:
                    violations.append(f'{path.relative_to(ROOT)}:{line_no}: inline select copy')
        for match in re.finditer(r"context\.strings\.(?:text|format)\('([^']+)'", text):
            referenced.add(match.group(1))
        for line_no, line in enumerate(text.splitlines(), 1):
            stripped = line.lstrip()
            if stripped.startswith('import ') or stripped.startswith('//') or stripped.startswith('///'):
                continue
            if accented_tr.search(line) and re.search(r"['\"]", line):
                violations.append(f'{path.relative_to(ROOT)}:{line_no}: Turkish literal outside localization')
            for pattern in literal_patterns:
                for match in pattern.finditer(line):
                    value = match.group(2).strip()
                    if value and not technical.fullmatch(value):
                        violations.append(f'{path.relative_to(ROOT)}:{line_no}: direct user copy {value!r}')
    missing = sorted(referenced - set(tr))
    if missing:
        fail(f'referenced localization keys missing from catalog: {missing[:12]}')
    if violations:
        print('\n'.join(f'FAIL: {item}' for item in violations[:30]))
        raise SystemExit(1)

    app_text = APP.read_text(encoding='utf-8')
    for marker in ("Locale('tr')", "Locale('en')", 'supportedLocales'):
        if marker not in app_text:
            fail(f'app locale configuration missing marker: {marker}')
    print(f'Localization gate passed: {len(tr)} shared TR/EN keys, {len(referenced)} referenced catalog keys, no direct UI copy.')


if __name__ == '__main__':
    main()
