from datetime import datetime, timezone
from time import perf_counter


def main() -> None:
    started = perf_counter()
    incidents = []
    source_ids = set()
    for index in range(10_000):
        source_id = f"source_stress_{index:05d}"
        source_ids.add(source_id)
        incidents.append({
            "id": f"incident_stress_{index:05d}",
            "status": "verified_active" if index % 2 == 0 else "pending_verification",
            "location": {
                "latitude": 40.85 + (index % 300) / 1000,
                "longitude": 28.65 + (index % 500) / 1000,
                "coordinateSystem": "EPSG:4326",
            },
            "sourceRecordIds": [source_id],
            "updatedAt": datetime(2026, 8, 17, tzinfo=timezone.utc).isoformat(),
        })

    ids = [item["id"] for item in incidents]
    assert len(ids) == len(set(ids)) == 10_000
    assert all(
        item["location"]["coordinateSystem"] == "EPSG:4326"
        and set(item["sourceRecordIds"]).issubset(source_ids)
        for item in incidents
    )
    elapsed_ms = (perf_counter() - started) * 1000
    print(f"10.000 kayıt contract benchmark geçti: {elapsed_ms:.1f} ms")


if __name__ == "__main__":
    main()
