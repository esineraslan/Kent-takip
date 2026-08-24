from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SKIP = {
    "docs/archive",
    "EKSTRA.md",
    "ROADMAP.md",
    "ARCHITECTURE.md",
    "RULES.md",
}
SKIP_DIRECTORY_NAMES = {"build", ".dart_tool"}
patterns = {
    "private-key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "api-key": re.compile(r"(?i)(?:api[_-]?key|secret|token)\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}"),
    "real-email": re.compile(r"\b[A-Za-z0-9._%+-]+@(?!demo\.invalid\b)[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
}
errors = []
for path in ROOT.rglob("*"):
    relative_path = path.relative_to(ROOT)
    if not path.is_file() or any(part.startswith(".") for part in relative_path.parts):
        continue
    relative = relative_path.as_posix()
    if any(part in SKIP_DIRECTORY_NAMES for part in relative_path.parts[:-1]):
        continue
    if any(relative == item or relative.startswith(item + "/") for item in SKIP):
        continue
    if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".zip"}:
        continue
    try:
        text = path.read_text(encoding="utf-8-sig")
    except UnicodeDecodeError:
        continue
    for label, pattern in patterns.items():
        if pattern.search(text):
            errors.append(f"{label}: {relative}")
if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print("Secret/PII kaynak taraması temiz")

