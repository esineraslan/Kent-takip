#!/usr/bin/env python3
"""Generate dependency/license evidence after dependency resolution.

The strict gate audits third-party resolved packages. First-party workspace packages
are listed separately and are governed by the repository license/policy rather than
being treated as external dependencies.
"""
from pathlib import Path
from urllib.parse import urlparse, unquote
import argparse
import json
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--strict', action='store_true')
args = parser.parse_args()
OUT = ROOT / 'build/dependency-license-report.txt'
OUT.parent.mkdir(parents=True, exist_ok=True)

pubspecs = [
    ROOT / 'pubspec.yaml',
    *ROOT.glob('apps/*/pubspec.yaml'),
    *ROOT.glob('packages/*/pubspec.yaml'),
]
direct = []
for manifest in pubspecs:
    if not manifest.exists():
        continue
    section = None
    for line in manifest.read_text(encoding='utf-8').splitlines():
        if re.match(r'^(dependencies|dev_dependencies):\s*$', line):
            section = line.split(':')[0]
            continue
        if re.match(r'^\S', line):
            section = None
        match = re.match(r'^  ([A-Za-z0-9_]+):\s*(.*)$', line)
        if section and match and match.group(1) not in {'flutter'}:
            direct.append((
                str(manifest.relative_to(ROOT)),
                section,
                match.group(1),
                match.group(2).strip(),
            ))


def _resolved_root(config: Path, root_uri: str) -> Path:
    if root_uri.startswith('file:'):
        return Path(unquote(urlparse(root_uri).path)).resolve()
    return (config.parent / root_uri).resolve()


def _is_first_party(path: Path) -> bool:
    try:
        path.relative_to(ROOT)
        return True
    except ValueError:
        return False


def _license_files(path: Path) -> list[Path]:
    """Find package license evidence without walking arbitrary parent trees.

    Pub cache packages conventionally ship LICENSE/COPYING in their package root.
    Flutter SDK packages may inherit the SDK's root LICENSE; inspect only the
    bounded SDK parent chain in that case.
    """
    found = [*path.glob('LICENSE*'), *path.glob('COPYING*')]
    if found:
        return found
    parts = {part.lower() for part in path.parts}
    if 'flutter' in parts:
        current = path
        for _ in range(5):
            current = current.parent
            if current == current.parent:
                break
            inherited = [*current.glob('LICENSE*'), *current.glob('COPYING*')]
            if inherited:
                return inherited
    return []


lines = [
    'Kent Takip dependency/license evidence',
    '',
    f'Direct declarations: {len(direct)}',
]
for row in sorted(set(direct)):
    lines.append(' | '.join(row))

config = ROOT / '.dart_tool/package_config.json'
if config.exists():
    data = json.loads(config.read_text(encoding='utf-8'))
    missing: list[str] = []
    third_party = 0
    first_party = 0
    inspected: list[str] = []
    for package in data.get('packages', []):
        root_uri = package.get('rootUri', '')
        root = _resolved_root(config, root_uri)
        if not root.exists():
            continue
        name = package.get('name', 'unknown')
        if _is_first_party(root):
            first_party += 1
            continue
        third_party += 1
        licenses = _license_files(root)
        if licenses:
            inspected.append(f'{name}: {licenses[0]}')
        else:
            missing.append(name)
    lines += [
        '',
        f'First-party workspace packages skipped from external license gate: {first_party}',
        f'Third-party resolved packages inspected: {third_party}',
        f'Third-party packages without LICENSE/COPYING evidence: {len(missing)}',
    ]
    if missing:
        lines += ['Missing evidence:', *sorted(missing)]
    if inspected:
        lines += ['', 'Resolved license evidence:', *sorted(inspected)]
    status = 'PASS' if third_party > 0 and not missing else 'REVIEW_REQUIRED'
else:
    lines += [
        '',
        'Resolved package license inspection: BLOCKED '
        '(run flutter pub get first; .dart_tool/package_config.json is absent).',
    ]
    status = 'BLOCKED'

lines += ['', f'Status: {status}']
OUT.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Dependency/license report written: {OUT.relative_to(ROOT)} ({status})')
if args.strict and status != 'PASS':
    raise SystemExit(1)
