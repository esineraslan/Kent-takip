#!/usr/bin/env python3
"""SDK-independent WP-19 hardening invariants."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')

def require(text: str, token: str, label: str) -> None:
    if token not in text:
        print(f'FAIL: {label}: missing {token!r}')
        raise SystemExit(1)

def main() -> None:
    server = read('apps/demo_server/lib/src/server.dart')
    source = read('packages/kent_takip_application/lib/src/source_governance.dart')
    ai = read('packages/kent_takip_application/lib/src/ai_analysis.dart')
    hardening = read('packages/kent_takip_application/lib/src/security_hardening.dart')
    commands = read('packages/kent_takip_application/lib/src/commands.dart')
    logger = read('apps/kent_takip_app/lib/src/logging/structured_logger.dart')

    if "'access-control-allow-origin': '*'" in server or '"access-control-allow-origin": "*"' in server:
        raise SystemExit('FAIL: wildcard CORS is forbidden')
    for token, label in [
        ('_allowedDemoOrigins', 'origin allow-list'),
        ('_securityHeaders()', 'security headers'),
        ('const Duration(hours: 8)', 'session expiry'),
        ('_failedBearerAttempts', 'brute-force delay'),
        ("action: 'original_media_access'", 'media denial audit'),
        ('_safeFailureMessage', 'safe error payloads'),
        ("humanDecisionReason: null", 'citizen projection internal-note stripping'),
        ("originalRef: null", 'citizen projection original-media stripping'),
    ]:
        require(server, token, label)
    for token in ('role', 'permissions', 'audit', 'token', 'originalref', '_reservedFixtureKeys', 'key.toLowerCase()'):
        require(source.lower() if token == 'originalref' else source, token, 'nested fixture escalation guard')
    require(ai, 'wrapUntrustedInput', 'AI prompt isolation')
    for token in ('sameMediaReference', 'impossibleLocationJump', 'mutationReplay'):
        require(hardening, token, 'measured abuse signals')
    require(commands, 'human_review_only_no_automatic_sanction', 'human-review-only abuse policy')
    for token in ('authorization', 'phone', 'email', 'originalref', 'latitude', 'longitude'):
        require(logger.lower(), token.lower(), 'structured log redaction')
    print('Security hardening source gate passed: origin/session/media/import/log/AI/abuse invariants are present.')

if __name__ == '__main__':
    main()
