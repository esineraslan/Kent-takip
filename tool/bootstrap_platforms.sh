#!/usr/bin/env bash
set -euo pipefail

expected="3.47.0"
actual="$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
if [[ "$actual" != "$expected" ]]; then
  echo "Flutter $expected gerekli; bulunan: $actual" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="$repo_root/apps/kent_takip_app"

(
  cd "$app_dir"
  flutter create \
    --platforms=android,ios,web \
    --org tr.gov.ibb \
    --project-name kent_takip_app \
    .
)

# Sadece Android debug derlemelerinde yerel Shelf sunucusuna HTTP erişimi açılır.
# Release manifesti cleartext izni almaz; paylaşımlı/üretim benzeri kurulum HTTPS
# kullanmak zorundadır.
install -D -m 0644 \
  "$repo_root/tool/platform_overlays/android/app/src/debug/AndroidManifest.xml" \
  "$app_dir/android/app/src/debug/AndroidManifest.xml"
install -D -m 0644 \
  "$repo_root/tool/platform_overlays/android/app/src/debug/res/xml/network_security_config.xml" \
  "$app_dir/android/app/src/debug/res/xml/network_security_config.xml"

# image_picker için gerekli iOS gizlilik açıklamaları idempotent biçimde eklenir.
python3 - "$app_dir/ios/Runner/Info.plist" <<'PY'
import plistlib
import sys

path = sys.argv[1]
with open(path, 'rb') as handle:
    data = plistlib.load(handle)
data['NSCameraUsageDescription'] = (
    'Kent Takip, bildirdiğiniz kent sorununu fotoğraflamanız için kamerayı kullanır.'
)
data['NSPhotoLibraryUsageDescription'] = (
    'Kent Takip, yalnız seçtiğiniz sorun fotoğrafına erişir.'
)
with open(path, 'wb') as handle:
    plistlib.dump(data, handle, sort_keys=False)
PY
