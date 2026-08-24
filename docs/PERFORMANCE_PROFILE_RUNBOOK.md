# İBB Kent Takip — WP-21 Performance Profile Runbook

Bu runbook kaynak benchmark'ının ölçemediği gerçek Flutter runtime bütçelerini toplar. Sonuçlar `build/wp21/` altında saklanır ve kabul raporuna işlenir.

## Ön koşul

Flutter 3.47.0, release/profile çalıştırabilen Android cihaz/emülatör, iOS cihaz/simülatör ve Chrome hazır olmalıdır. Testler sentetik demo veriyle çalışır.

## Zorunlu ölçümler

1. `dart run tool/benchmark_wp21.dart --out build/wp21/performance_report.json`
2. Android profile modda temiz açılış, warm start ve ana route geçişi trace'i.
3. 10.000 kayıt staff queue arama/filter/sort ve map pan/zoom sırasında frame timeline.
4. DevTools memory snapshot: başlangıç, 10K liste sonrası, map+thumbnail sonrası ve route geri dönüşü.
5. Image cache gözlemi; orijinal medya yerine thumbnail/public ref kullanımı.
6. Network flapping, 429, 503, malformed JSON, server restart ve WebSocket reconnect.
7. Kamera açıkken background→resume ve Android lost-data recovery.
8. Düşük depolama/media quota; draft ve son geçerli snapshot korunumu.

## Bütçeler

- warm local first interaction < 2 s
- web first interaction < 4 s; tile bekletmez
- 60 Hz route/frame hedefi 16.667 ms
- seed parse+validation < 300 ms
- 10K queue search/filter/sort < 150 ms (250 ms debounce sonrası)
- 10K map projection+cluster CI source bütçesi < 250 ms
- snapshot < 3 MiB, media hariç
- AI manual fallback budget 4 s

Bütçe aşımı sessiz kabul edilmez. Ölçüm cihazı/koşulu raporlanır; kalıcı bütçe değişikliği yalnız ADR ile yapılır.
