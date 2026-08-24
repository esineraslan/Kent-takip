#!/usr/bin/env python3
"""SDK-independent WP-21/WP-22 completeness/traceability gate."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []

def need(path: str, snippets=()):
    p = ROOT / path
    if not p.exists():
        errors.append(f"missing: {path}")
        return ""
    text = p.read_text(encoding="utf-8-sig")
    for snippet in snippets:
        if snippet not in text:
            errors.append(f"{path}: missing marker {snippet!r}")
    return text

need("packages/kent_takip_application/lib/src/performance_reliability.dart", ["PerformanceBudgets", "OfflineStatePolicy", "retryIdempotent"])
need("tool/benchmark_wp21.dart", ["10000", "PerformanceMetric.mapProjection"])
need("apps/kent_takip_app/lib/src/storage/remote_demo_data_gateway.dart", ["cacheStore", "retryIdempotent", "_scheduleReconnect"])
need("packages/kent_takip_persistence/test/wp21_recovery_test.dart", ["migration", "quota"])
need("apps/kent_takip_app/test/wp21/remote_resilience_test.dart", ["429", "malformed"])
need("tool/check_coverage.py", ["80.0", "90.0"])
need("tool/check_golden_baselines.py", ["approved"])
need("docs/ACCEPTANCE_REPORT.md", ["E2E-30", "P0/P1"])

state_matrix_path = ROOT / "docs/screen_state_matrix.json"
if not state_matrix_path.exists():
    errors.append("missing: docs/screen_state_matrix.json")
else:
    state_data = json.loads(state_matrix_path.read_text(encoding="utf-8-sig"))
    screens = state_data.get("screens", [])
    state_ids = {item.get("id") for item in screens}
    required_screen_ids = {f"W-{i:02d}" for i in range(11)}
    missing_screen_ids = sorted(required_screen_ids - state_ids)
    if missing_screen_ids:
        errors.append(f"screen state matrix missing: {missing_screen_ids}")
    for item in screens:
        implementation = item.get("implementation")
        if not implementation or not (ROOT / implementation).exists():
            errors.append(f"{item.get('id')}: missing implementation {implementation}")
        states = set(item.get("states", []))
        if item.get("id") != "W-00":
            required_states = {"loading", "content", "empty", "offline_with_cache", "recoverable_error", "blocking_error"}
            missing_states = sorted(required_states - states)
            if missing_states:
                errors.append(f"{item.get('id')}: missing states {missing_states}")
architecture = need("ARCHITECTURE.md")
ids = {int(x) for x in re.findall(r"E2E-(\d{2})", architecture)}
missing_ids = sorted(set(range(1, 31)) - ids)
if missing_ids:
    errors.append(f"ARCHITECTURE missing E2E ids: {missing_ids}")

matrix_path = ROOT / "docs/acceptance_matrix.json"
if not matrix_path.exists():
    errors.append("missing: docs/acceptance_matrix.json")
else:
    data = json.loads(matrix_path.read_text(encoding="utf-8-sig"))
    scenarios = data.get("scenarios", [])
    matrix_ids = {int(item["id"].split("-")[1]) for item in scenarios if re.fullmatch(r"E2E-\d{2}", item.get("id", ""))}
    missing = sorted(set(range(1, 31)) - matrix_ids)
    if missing:
        errors.append(f"acceptance matrix missing: {missing}")
    for item in scenarios:
        tests = item.get("tests", [])
        if not tests:
            errors.append(f"{item.get('id')}: no tests mapped")
        for test in tests:
            if not (ROOT / test).exists():
                errors.append(f"{item.get('id')}: missing mapped test {test}")

quality = need(".github/workflows/quality.yml")
for marker in ["benchmark_wp21.dart", "check_coverage.py", "check_golden_baselines.py", "integration_test", "flutter build web", "flutter build apk", "flutter build ios"]:
    if marker not in quality:
        errors.append(f"quality.yml missing WP21/22 gate: {marker}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print("WP-21/WP-22 kaynak, E2E-01..30 izlenebilirlik ve CI kapıları doğrulandı.")
