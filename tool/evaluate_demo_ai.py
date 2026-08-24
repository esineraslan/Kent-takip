#!/usr/bin/env python3
"""WP-10 deterministik AI fixture metriklerini yeniden hesaplar ve kanıtı doğrular."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "apps/kent_takip_app/assets/demo_data/v1/ai_evaluation_fixture.json"
REPORT = ROOT / "docs/quality/AI_EVALUATION_REPORT.json"


def ratio(numerator: int, denominator: int) -> float:
    return round(numerator / denominator, 6) if denominator else 1.0


fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
expected = json.loads(REPORT.read_text(encoding="utf-8"))
cases = fixture["cases"]
valid = [case for case in cases if case["responseValid"]]
unsafe = [case for case in valid if case["containsSensitiveMedia"]]
duplicates = [case for case in valid if case["expectedDuplicate"]]

actual = {
    "fixtureVersion": fixture["fixtureVersion"],
    "caseCount": len(cases),
    "validCaseCount": len(valid),
    "categoryAccuracy": ratio(
        sum(case["expectedCategory"] == case["predictedCategory"] for case in valid),
        len(valid),
    ),
    "privacyFalseNegativeRate": ratio(
        sum(case["predictedPrivacy"] == "safe" for case in unsafe), len(unsafe)
    ),
    "duplicateRecall": ratio(
        sum(case["predictedDuplicate"] for case in duplicates), len(duplicates)
    ),
    "validResponseRate": ratio(len(valid), len(cases)),
}

for key, value in actual.items():
    if expected.get(key) != value:
        raise SystemExit(f"AI evaluation mismatch: {key}: {expected.get(key)!r} != {value!r}")

gates = expected["gates"]
passed = (
    actual["categoryAccuracy"] >= gates["categoryAccuracyMin"]
    and actual["privacyFalseNegativeRate"] <= gates["privacyFalseNegativeRateMax"]
    and actual["duplicateRecall"] >= gates["duplicateRecallMin"]
    and actual["validResponseRate"] >= gates["validResponseRateMin"]
)
if passed is not expected["passed"]:
    raise SystemExit("AI evaluation gate result does not match evidence report")

print(json.dumps({**actual, "passed": passed}, ensure_ascii=False, sort_keys=True))
