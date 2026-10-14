# Panduan Operasional LNBits untuk Nusacoin

Panduan menjalankan LNBits sebagai backend dompet sekolah / komunitas
di atas `lnd-nux` (testnet maupun mainnet). Ditulis dari pengalaman
operasi nyata — berisi jebakan yang sudah terbukti terjadi.

## Prasyarat

- LNBits dari fork `Nusanian/lnbits`, branch `nusacoin`
  (sudah termasuk patch kompatibilitas `lnd-nux`).
- Python virtualenv, mis. `~/lnbits/lnb_venv`.
- Backend wallet `LndWallet` terkonfigurasi di `.env`
  (gRPC lnd-nux, TLS cert, macaroon — lihat panduan instalasi).
- Dependensi websocket: `~/lnbits/lnb_venv/bin/pip install websockets`
  (tanpa ini, handshake WebSocket dijawab 405/400 — lihat troubleshooting).

## Lokasi komponen (contoh)

| Komponen | Lokasi |
|---|---|
| Repo LNBits | `~/lnbits` |
| Virtualenv | `~/lnbits/lnb_venv` |
| Konfigurasi | `~/lnbits/.env` (aman saat restart — tidak hilang) |
| Database | `~/lnbits/data/database.sqlite3` (JANGAN dihapus sembarangan) |
| Port | `5000`, bind `0.0.0.0` (bisa diakses dari IP publik) |

Sesuaikan path dengan lokasi instalasi masing-masing.

## Cara start yang benar

```bash
cd ~/lnbits && source lnb_venv/bin/activate
uvicorn lnbits.__main__:app --host 0.0.0.0 --port 5000
```

- **WAJIB dijalankan dari direktori repo** (tempat folder `lnbits/`
  berada). Kode memakai path relatif `lnbits/static`; start dari
  direktori lain → error
  `RuntimeError: Directory 'lnbits/static' does not exist`.
- Untuk jalan di background:
  ```bash
  nohup uvicorn lnbits.__main__:app --host 0.0.0.0 --port 5000 > uvicorn.log 2>&1 &
  ```
- Verifikasi: tunggu baris `LNbits started` di log, lalu:
  ```bash
  ss -tlnp | grep :5000
  ```
  harus menunjukkan `LISTEN` di `0.0.0.0:5000`.

## Cara stop

```bash
ss -tlnp | grep :5000   # catat PID-nya
kill <PID>
sleep 2
ss -tlnp | grep :5000   # harus kosong = sudah mati
```

- **JANGAN andalkan `pkill -f "uvicorn.*lnbits"`** — terbukti tidak
  selalu mempan; proses lama bisa tetap hidup dan memegang port 5000
  sehingga start baru mati dengan `address already in use`.
- Kalau `kill` biasa tidak mempan: `kill -9 <PID>`.

## Restart lengkap

```bash
# 0. (sekali saja, bila belum pernah) pastikan paket websocket ada:
~/lnbits/lnb_venv/bin/pip install websockets

# 1. stop seperti di atas (ss + kill by PID, verifikasi port kosong)

# 2. start dari direktori repo seperti di atas

# 3. verifikasi: "LNbits started" di log + ss menunjukkan LISTEN
```

## Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `RuntimeError: Directory 'lnbits/static' does not exist` | start bukan dari direktori repo | `cd` ke direktori repo dulu sebelum start |
| `[Errno 98] address already in use` | proses lama masih hidup | `ss -tlnp \| grep :5000`, `kill <PID>` |
| WebSocket handshake dijawab 405/400 | paket `websockets` belum terinstal di venv → uvicorn tak bisa upgrade WebSocket | `pip install websockets` di venv + restart |
| Aplikasi HP banjir log + CPU tinggi, saldo spinner terus | bug retry WebSocket di aplikasi lama | update aplikasi dompet ke versi terbaru |
| Membuat wallet: Web UI gagal login | keterbatasan auth Web UI 1.6 | buat via API: `PUT /api/v1/auth/first_install`, lalu `POST /api/v1/auth`, lalu `POST /api/v1/wallet` dengan header `Authorization: Bearer <token>` |
| Lupa apakah proses masih jalan | — | `ss -tlnp \| grep :5000` atau `ps aux \| grep uvicorn \| grep -v grep` |

## Catatan denominasi

Untuk Nusacoin, JANGAN set `LNBITS_DENOMINATION` ke nilai custom
(mis. `nusan`) — nilai itu dilempar ke `Intl.NumberFormat` sebagai
currency code dan bisa memicu `RangeError`, dan untuk denominasi
selain sats nominal invoice bisa dikali 100 oleh kode LNBits.
Pakai default `sats`: **1 sat = 1 nusan** di level API, branding
`nusan` dilakukan di UI aplikasi.

## Langkah lanjut yang disarankan

- [ ] Systemd unit agar auto-start saat boot dan restart lebih rapi.
- [ ] Saat pilot produksi: pasang reverse proxy + TLS (Caddy paling
      mudah — sertifikat otomatis), tutup port 5000 dari publik.
      WebSocket ikut jalan lewat `wss://` tanpa setting tambahan.
- [ ] Backup berkala `data/database.sqlite3`.
