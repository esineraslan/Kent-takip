#!/usr/bin/env python3
"""WP-22 approved golden baseline gate. Does not fabricate image evidence."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

VIEWPORTS = [
    "citizen_320x568", "citizen_390x844", "citizen_768x1024", "citizen_1024x768",
    "staff_1024x768", "staff_1280x800", "staff_1440x900", "staff_1600x1000",
]
LOCALES = ["tr", "en-long"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    root = Path("apps/kent_takip_app/test/goldens/wp05")
    expected = [root / f"{viewport}_{locale}.png" for locale in LOCALES for viewport in VIEWPORTS]
    missing = [str(p) for p in expected if not p.exists() or p.stat().st_size < 512]
    review_path = Path("docs/golden_review.json")
    approved = False
    if review_path.exists():
        try:
            review = json.loads(review_path.read_text(encoding="utf-8-sig"))
            approved = review.get("status") == "approved" and review.get("baselineCount") == len(expected)
        except Exception:
            approved = False
    if missing:
        print(f"BLOCKED: {len(missing)}/{len(expected)} golden baseline eksik/geçersiz.")
    if not approved:
        print("BLOCKED: docs/golden_review.json tasarım onayı 'approved' değil.")
    ok = not missing and approved
    return 0 if ok or not args.strict else 2


if __name__ == "__main__":
    raise SystemExit(main())
