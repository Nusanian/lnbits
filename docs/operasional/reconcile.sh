#!/bin/bash
# reconcile.sh — Rekonsiliasi saldo virtual LNBits vs dana riil node LSP
# Prinsip: total saldo semua wallet murid TIDAK BOLEH melebihi dana yang
# benar-benar ada di node Lightning (proof-of-reserves sederhana).
# Jalankan manual mingguan, atau via cron dengan output ke log.
set -e

DB="/root/lnbits/data/database.sqlite3"
LNCLI="/root/lnd-nux/lncli"
LND_FLAGS="--network=testnet --chain=nusacoin"   # TODO: sesuaikan untuk mainnet

echo "=== Rekonsiliasi $(date '+%Y-%m-%d %H:%M') ==="

# 1. Total saldo virtual dari database LNBits
#    (nama tabel/kolom: verifikasi sekali dengan .schema bila LNBits di-upgrade)
VIRTUAL_MSAT=$(sqlite3 "$DB" "SELECT COALESCE(SUM(balance),0) FROM balances;" 2>/dev/null || echo "QUERY_GAGAL")
echo "Total saldo virtual (msat): $VIRTUAL_MSAT"

# 2. Cek anomali: saldo negatif
NEGATIF=$(sqlite3 "$DB" "SELECT COUNT(*) FROM balances WHERE balance < 0;" 2>/dev/null || echo "?")
echo "Wallet bersaldo negatif: $NEGATIF  (harus 0)"

# 3. Saldo riil node LSP (on-chain + channel)
if [ -x "$LNCLI" ]; then
  ONCHAIN=$($LNCLI $LND_FLAGS walletbalance 2>/dev/null | grep -oP '"confirmed_balance":\s*"\K[0-9]+' | head -1)
  CHANNEL=$($LNCLI $LND_FLAGS channelbalance 2>/dev/null | grep -oP '"balance":\s*"\K[0-9]+' | head -1)
  echo "Node on-chain (sat): ${ONCHAIN:-?}"
  echo "Node channel (sat): ${CHANNEL:-?}"
else
  echo "lncli tidak ditemukan, lewati cek node."
fi

echo ""
echo "Aturan: total virtual (dikonversi ke sat) <= on-chain + channel."
echo "Selisih = alarm, investigasi sebelum operasional lanjut."
