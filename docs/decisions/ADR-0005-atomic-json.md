# ADR-0005 — Atomik JSON kalıcılığı

Durum: Kabul edildi  
Tarih: 17 Ağustos 2026

Karar: IO store temp→flush→read/validate→backup→atomic rename; web store iki slot→read/validate→active pointer uygular. Doğrudan active overwrite kararı geçersizdir.

