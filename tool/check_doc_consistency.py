from pathlib import Path
import sys
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "PRODUCT.md", "USER_FLOWS.md", "DESIGN.md", "ARCHITECTURE.md",
    "AI_SYSTEM.md", "DATA_SOURCES.md", "RULES.md", "docs/TRACEABILITY.md",
]
errors = []
for path in ROOT.rglob("*.md"):
    raw = path.read_bytes()
    relative = str(path.relative_to(ROOT))
    if not raw.startswith(b"\xef\xbb\xbf"):
        errors.append(f"UTF-8 BOM eksik: {relative}")
    text = raw.decode("utf-8-sig")
    if unicodedata.normalize("NFC", text) != text:
        errors.append(f"NFC değil: {relative}")

for relative in REQUIRED:
    path = ROOT / relative
    if not path.exists():
        errors.append(f"Eksik belge: {relative}")
        continue
    text = path.read_text(encoding="utf-8-sig")
    if "İBB Kent Takip" not in text:
        errors.append(f"Ürün adı eksik: {relative}")

product = (ROOT / "PRODUCT.md").read_text(encoding="utf-8-sig")
for phrase in ["İstanbul Senin/153", "UrbanIncident", "Fotoğrafsız devam", "vatandaş güven skoru yoktur"]:
    if phrase.casefold() not in product.casefold():
        errors.append(f"PRODUCT kararı eksik: {phrase}")

adr_count = len(list((ROOT / "docs/decisions").glob("ADR-*.md")))
if adr_count < 8:
    errors.append(f"ADR sayısı yetersiz: {adr_count}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print(f"Belge tutarlılığı doğrulandı: {len(REQUIRED)} belge, {adr_count} ADR")
