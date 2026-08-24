from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "apps/kent_takip_app/assets/demo_data/v1/snapshot.json"
manifest_path = ROOT / "apps/kent_takip_app/assets/demo_data/v1/manifest.json"
data = json.loads(path.read_text(encoding="utf-8"))
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
canonical = json.dumps(data["payload"], ensure_ascii=False, separators=(",", ":"), sort_keys=True)
expected = "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()
errors = []
if manifest.get("synthetic") is not True:
    errors.append("Seed manifest synthetic=true olmalıdır")
if manifest.get("schemaVersion") != data.get("schemaVersion"):
    errors.append("Manifest ve snapshot schemaVersion uyuşmuyor")
if manifest.get("seedVersion") != data.get("seedVersion"):
    errors.append("Manifest ve snapshot seedVersion uyuşmuyor")
if data["checksum"] != expected:
    errors.append(f"Checksum uyuşmuyor: expected={expected}")

payload = data["payload"]
account_ids = {item["id"] for item in payload["accounts"]}
media_ids = {item["id"] for item in payload["media"]}
analysis_ids = {item["id"] for item in payload["analyses"]}
incident_ids = {item["id"] for item in payload["incidents"]}
source_record_ids = {item["id"] for item in payload["sourceRecords"]}

for collection_name in [
    "accounts", "reports", "incidents", "municipalWorks", "media",
    "analyses", "sourceAuthorities", "sourceRecords", "timeline",
    "notifications", "auditEvents", "privacyRequests", "restrictions",
    "demoScenarios",
]:
    values = payload[collection_name]
    ids = [item["id"] for item in values]
    if len(ids) != len(set(ids)):
        errors.append(f"Mükerrer ID: {collection_name}")

for report in payload["reports"]:
    if report["ownerId"] not in account_ids:
        errors.append(f"Eksik owner: {report['id']}")
    if not set(report["mediaIds"]).issubset(media_ids):
        errors.append(f"Eksik medya: {report['id']}")
    if report.get("analysisId") and report["analysisId"] not in analysis_ids:
        errors.append(f"Eksik analiz: {report['id']}")
    if report.get("linkedIncidentId") and report["linkedIncidentId"] not in incident_ids:
        errors.append(f"Eksik incident: {report['id']}")
    location = report["location"]
    if location.get("coordinateSystem") != "EPSG:4326":
        errors.append(f"WGS84 değil: {report['id']}")

for incident in payload["incidents"]:
    if not set(incident["reportIds"]).issubset({item["id"] for item in payload["reports"]}):
        errors.append(f"Eksik report referansı: {incident['id']}")
    if not set(incident["sourceRecordIds"]).issubset(source_record_ids):
        errors.append(f"Eksik source referansı: {incident['id']}")
    if not incident["reportIds"] and not incident["sourceRecordIds"]:
        errors.append(f"Kaynak sinyalsiz incident: {incident['id']}")

for media in payload["media"]:
    if media.get("publicRef") and media.get("privacyStatus") != "safe":
        errors.append(f"Güvensiz public medya: {media['id']}")
    for key in ("originalRef", "publicRef"):
        reference = media.get(key)
        if reference is None:
            continue
        if not reference.startswith("asset://demo_media/"):
            errors.append(f"Geçersiz asset URI: {reference}")
            continue
        asset = ROOT / "apps/kent_takip_app/assets" / reference.removeprefix("asset://")
        if not asset.is_file():
            errors.append(f"Eksik asset: {asset.relative_to(ROOT)}")

forbidden = {"citizentrustscore", "citizentrustsignal", "userscore"}
def walk(value, path="payload"):
    if isinstance(value, dict):
        for key, child in value.items():
            if key.lower().replace("_", "") in forbidden:
                errors.append(f"Yasak kişi puanı alanı: {path}.{key}")
            walk(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, f"{path}[{index}]")
walk(payload)

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print(f"Seed doğrulandı: revision={data['revision']}, checksum={expected}")
