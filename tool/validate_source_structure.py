#!/usr/bin/env python3
"""SDK-independent source structure checks for the Kent Takip workspace."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
PAIRS = {")": "(", "]": "[", "}": "{"}


def validate_dart(path: Path) -> list[str]:
    source = path.read_text(encoding="utf-8-sig")
    errors: list[str] = []
    stack: list[tuple[str, int]] = []
    index = 0
    line = 1
    quote: str | None = None
    triple = False
    block_comment = 0
    line_comment = False
    while index < len(source):
        character = source[index]
        pair = source[index : index + 2]
        if character == "\n":
            line += 1
            line_comment = False
            index += 1
            continue
        if line_comment:
            index += 1
            continue
        if block_comment:
            if pair == "/*":
                block_comment += 1
                index += 2
                continue
            if pair == "*/":
                block_comment -= 1
                index += 2
                continue
            index += 1
            continue
        if quote:
            if character == "\\" and not triple:
                index += 2
                continue
            if triple and source.startswith(quote * 3, index):
                quote = None
                triple = False
                index += 3
                continue
            if not triple and character == quote:
                quote = None
            index += 1
            continue
        if pair == "//":
            line_comment = True
            index += 2
            continue
        if pair == "/*":
            block_comment = 1
            index += 2
            continue
        if character in "'\"":
            quote = character
            triple = source.startswith(character * 3, index)
            index += 3 if triple else 1
            continue
        if character in "([{":
            stack.append((character, line))
        elif character in ")]}":
            if not stack or stack[-1][0] != PAIRS[character]:
                errors.append(f"{path.relative_to(ROOT)}:{line}: unexpected {character}")
                break
            stack.pop()
        index += 1
    if stack:
        token, token_line = stack[-1]
        errors.append(f"{path.relative_to(ROOT)}:{token_line}: unclosed {token}")
    declarations = re.findall(
        r"(?m)^(?:final |base |sealed |abstract )?class\s+(\w+)|^enum\s+(\w+)",
        source,
    )
    names = [left or right for left, right in declarations]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        errors.append(
            f"{path.relative_to(ROOT)}: duplicate declarations {duplicates}"
        )
    for enum_name, body in re.findall(r"\benum\s+(\w+)\s*\{([^}]*)\}", source, re.S):
        constants = body.split(';', 1)[0]
        members = []
        for raw in constants.split(','):
            match = re.match(r"\s*(\w+)", raw)
            if match:
                members.append(match.group(1))
        repeated = sorted({name for name in members if members.count(name) > 1})
        if repeated:
            errors.append(
                f"{path.relative_to(ROOT)}: enum {enum_name} duplicate members {repeated}"
            )
    return errors


def main() -> int:
    errors: list[str] = []
    for path in sorted(ROOT.rglob("*.json")):
        try:
            json.loads(path.read_text(encoding="utf-8-sig"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {error}")
    for path in sorted(ROOT.rglob("*.xml")):
        try:
            ElementTree.parse(path)
        except (OSError, ElementTree.ParseError) as error:
            errors.append(f"{path.relative_to(ROOT)}: invalid XML: {error}")
    for path in sorted(ROOT.rglob("*.dart")):
        errors.extend(validate_dart(path))
    for path in sorted(ROOT.rglob("*.md")):
        if not path.read_bytes().startswith(b"\xef\xbb\xbf"):
            errors.append(f"{path.relative_to(ROOT)}: UTF-8 BOM missing")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("JSON/XML, Dart delimiter/declaration ve belge kodlama kontrolleri geçti.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
