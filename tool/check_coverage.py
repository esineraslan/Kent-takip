#!/usr/bin/env python3
"""WP-22 LCOV gate: overall >=80%, critical business/security branches >=90%."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CRITICAL_MARKERS = (
    "packages/kent_takip_application/lib/src/commands.dart",
    "packages/kent_takip_application/lib/src/staff_commands.dart",
    "packages/kent_takip_application/lib/src/field_operations.dart",
    "packages/kent_takip_application/lib/src/source_governance.dart",
    "packages/kent_takip_application/lib/src/administration.dart",
    "packages/kent_takip_application/lib/src/security_hardening.dart",
    "packages/kent_takip_persistence/lib/src/",
    "apps/kent_takip_app/lib/src/storage/remote_demo_data_gateway.dart",
)


def parse(path: Path):
    files = {}
    current = None
    lf = lh = 0
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if raw.startswith("SF:"):
            current = raw[3:].replace("\\", "/")
            lf = lh = 0
        elif raw.startswith("LF:"):
            lf = int(raw[3:])
        elif raw.startswith("LH:"):
            lh = int(raw[3:])
        elif raw == "end_of_record" and current:
            files[current] = (lh, lf)
            current = None
    return files


def ratio(hit: int, found: int) -> float:
    return 100.0 if found == 0 else hit * 100.0 / found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lcov", default="apps/kent_takip_app/coverage/lcov.info")
    parser.add_argument("--overall", type=float, default=80.0)
    parser.add_argument("--critical", type=float, default=90.0)
    parser.add_argument("--out", default="build/wp22/coverage_report.json")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    source = Path(args.lcov)
    if not source.exists():
        message = f"BLOCKED: LCOV bulunamadı: {source}"
        print(message)
        return 2 if args.strict else 0
    files = parse(source)
    overall_lh = sum(v[0] for v in files.values())
    overall_lf = sum(v[1] for v in files.values())
    critical_files = {
        name: values
        for name, values in files.items()
        if any(marker in name for marker in CRITICAL_MARKERS)
    }
    critical_lh = sum(v[0] for v in critical_files.values())
    critical_lf = sum(v[1] for v in critical_files.values())
    overall_pct = ratio(overall_lh, overall_lf)
    critical_pct = ratio(critical_lh, critical_lf) if critical_files else 0.0
    report = {
        "overall": {"hit": overall_lh, "found": overall_lf, "percent": round(overall_pct, 2), "threshold": args.overall},
        "critical": {"hit": critical_lh, "found": critical_lf, "percent": round(critical_pct, 2), "threshold": args.critical},
        "criticalFileCount": len(critical_files),
        "criticalFiles": sorted(critical_files),
    }
    target = Path(args.out)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    ok = overall_pct >= args.overall and critical_pct >= args.critical and bool(critical_files)
    print(f"overall={overall_pct:.2f}% (>= {args.overall:.0f}%) critical={critical_pct:.2f}% (>= {args.critical:.0f}%)")
    if not critical_files:
        print("FAIL: kritik kaynaklar LCOV içinde görünmüyor.")
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
