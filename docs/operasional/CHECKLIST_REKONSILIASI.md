# Checklist Rekonsiliasi & Backup — Operasional LNBits Sekolah

## Backup otomatis (harian)

**Jadwal:** cron tiap jam 02:00 WIB
```
0 2 * * * /root/scripts/backup-lnbits.sh >> /root/backup/backup.log 2>&1
```

**Yang di-backup:**
- `database.sqlite3` (via `sqlite3 .backup` — aman walau DB sedang ditulis)
- `.env` (chmod 600)

**Retensi:** 14 hari, otomatis hapus yang lama.

**Verifikasi bulanan:** restore satu file backup ke direktori sementara, pastikan bisa dibuka (`sqlite3 backup.db "SELECT COUNT(*) FROM balances;"`).

## Rekonsiliasi (mingguan, manual)

Jalankan `/root/scripts/reconcile.sh`, pastikan:

- [ ] Total saldo virtual ≤ dana riil node (on-chain + channel)
- [ ] Nol wallet bersaldo negatif
- [ ] Tidak ada lonjakan saldo tak wajar vs minggu lalu (catat angkanya)

**Jika selisih ditemukan:**
1. Hentikan top-up/withdraw sementara
2. Bandingkan `data/` dengan backup terakhir yang sehat → cari transaksi penyebab
3. Jangan edit DB manual kecuali sudah paham akar masalahnya

## Catatan

- Skema tabel (`balances.balance`) — verifikasi ulang dengan `sqlite3 ... ".schema balances"` setiap kali LNBits di-upgrade versi mayor.
- Untuk mainnet: sesuaikan `LND_FLAGS` di `reconcile.sh` dan tambahkan backup macaroon + seed ke `backup-lnbits.sh`.
