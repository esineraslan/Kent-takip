#!/usr/bin/env python3
"""Build a deterministic release-evidence manifest without inventing missing artifacts."""
from __future__ import annotations
import argparse, hashlib, json, re, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_PUBSPEC = ROOT / 'apps/kent_takip_app/pubspec.yaml'

CANDIDATES = {
    'android_apk': ROOT / 'apps/kent_takip_app/build/app/outputs/flutter-apk/app-release.apk',
    'android_aab': ROOT / 'apps/kent_takip_app/build/app/outputs/bundle/release/app-release.aab',
    'web_index': ROOT / 'apps/kent_takip_app/build/web/index.html',
    'dependency_sbom': ROOT / 'dependency-sbom.json',
    'coverage_lcov': ROOT / 'apps/kent_takip_app/coverage/lcov.info',
    'performance_report': ROOT / 'build/wp21/performance_report.json',
    'ios_info_plist': ROOT / 'apps/kent_takip_app/build/ios/iphoneos/Runner.app/Info.plist',
}

def sha(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()


def source_tree_sha() -> str:
    h=hashlib.sha256()
    excluded={'docs/RELEASE_MANIFEST.md','docs/release/RELEASE_EVIDENCE_SOURCE.json'}
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file(): continue
        rel=path.relative_to(ROOT).as_posix()
        if rel in excluded or rel.startswith('build/') or rel.startswith('.git/') or '/build/' in rel or '/.dart_tool/' in rel:
            continue
        h.update(rel.encode('utf-8')); h.update(b'\0'); h.update(bytes.fromhex(sha(path)))
    return h.hexdigest()

def version() -> str:
    text=APP_PUBSPEC.read_text(encoding='utf-8')
    m=re.search(r'^version:\s*(\S+)\s*$', text, re.M)
    if not m: raise SystemExit('version missing')
    return m.group(1)

def git_commit() -> str | None:
    try:
        return subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True,stderr=subprocess.DEVNULL).strip()
    except Exception:
        return None

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument('--out', default='build/wp23/release_evidence.json')
    args=ap.parse_args()
    result={
        'releaseVersion': version(),
        'gitCommit': git_commit(),
        'sourceMode': 'git' if git_commit() else 'source_archive_without_git_metadata',
        'sourceTreeSha256ExcludingReleaseManifest': source_tree_sha(),
        'artifacts': {},
    }
    for name,path in CANDIDATES.items():
        result['artifacts'][name]={
            'path': str(path.relative_to(ROOT)),
            'status': 'present' if path.is_file() else 'missing',
            'sha256': sha(path) if path.is_file() else None,
            'bytes': path.stat().st_size if path.is_file() else None,
        }
    out=ROOT/args.out
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(out)

if __name__=='__main__': main()
