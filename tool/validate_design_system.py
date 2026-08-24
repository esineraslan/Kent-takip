#!/usr/bin/env python3
"""WP-05 design token and brand-asset guardrail."""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
UI_ROOT = ROOT / "apps/kent_takip_app/lib"
TOKEN_FILE = UI_ROOT / "src/ui/design/tokens.dart"
MANIFEST = ROOT / "docs/BRAND_ASSET_MANIFEST.json"

BRAND_LITERALS = {
    "003378", "0E3B83", "1457A6", "DCE8F7", "F2F7FF", "C31E60", "A91850"
}
FONT_LITERALS = {"Rubik", "Urbanist"}
CONTRAST_PAIRS = {
    "text-strong/page": ("172033", "F4F7FB", 4.5),
    "text-default/white": ("30394D", "FFFFFF", 4.5),
    "white/brand-blue-800": ("FFFFFF", "0E3B83", 4.5),
    "white/danger": ("FFFFFF", "9A1C2A", 4.5),
    "planned-ink/planned": ("3B3000", "F4C542", 4.5),
    "text-muted/white": ("5D687C", "FFFFFF", 4.5),
}


def _luminance(hex_value: str) -> float:
    channels = [int(hex_value[index:index + 2], 16) / 255 for index in (0, 2, 4)]
    linear = [
        value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
        for value in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def _contrast(left: str, right: str) -> float:
    high, low = sorted((_luminance(left), _luminance(right)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def main() -> int:
    errors: list[str] = []
    token_source = TOKEN_FILE.read_text(encoding="utf-8")
    for literal in BRAND_LITERALS:
        if literal not in token_source:
            errors.append(f"Eksik marka tokenı: #{literal}")
    for family in FONT_LITERALS:
        if repr(family) not in token_source:
            errors.append(f"Eksik font tokenı: {family}")
    for label, (foreground, background, minimum) in CONTRAST_PAIRS.items():
        ratio = _contrast(foreground, background)
        if ratio < minimum:
            errors.append(
                f"Kontrast yetersiz: {label} {ratio:.2f}:1 < {minimum:.1f}:1"
            )

    for path in UI_ROOT.rglob("*.dart"):
        if path == TOKEN_FILE:
            continue
        source = path.read_text(encoding="utf-8")
        for literal in BRAND_LITERALS:
            if re.search(rf"0x(?:FF)?{literal}\b", source, re.IGNORECASE):
                errors.append(f"Literal marka rengi token dışında: {path.relative_to(ROOT)} #{literal}")
        for family in FONT_LITERALS:
            if re.search(rf"fontFamily\s*:\s*['\"]{family}['\"]", source):
                errors.append(f"Literal font token dışında: {path.relative_to(ROOT)} {family}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1:
        errors.append("Marka manifest schemaVersion 1 olmalıdır.")
    for item in manifest.get("assets", []):
        relative = item.get("path")
        expected = item.get("sha256")
        if not isinstance(relative, str) or not isinstance(expected, str):
            errors.append("Manifest asset path/sha256 alanı geçersiz.")
            continue
        asset_path = ROOT / relative
        if not asset_path.is_file():
            errors.append(f"Manifest asseti eksik: {relative}")
            continue
        actual = hashlib.sha256(asset_path.read_bytes()).hexdigest()
        if actual != expected:
            errors.append(f"Manifest checksum uyuşmazlığı: {relative}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Tasarım tokenları ve marka asset manifesti doğrulandı.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
