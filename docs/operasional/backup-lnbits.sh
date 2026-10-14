#!/bin/bash
# backup-lnbits.sh — Backup otomatis LNBits (database + .env)
# Dijadwalkan via cron harian. Retensi 14 hari.
set -e

BACKUP_DIR="/root/backup/lnbits"
RETENTION_DAYS=14
DATE=$(date +%Y%m%d-%H%M%S)
DB="/root/lnbits/data/database.sqlite3"

mkdir -p "$BACKUP_DIR"

# Database: pakai sqlite3 .backup (aman walau DB sedang ditulis, tidak seperti cp mentah)
if [ -f "$DB" ]; then
  sqlite3 "$DB" ".backup '$BACKUP_DIR/database-$DATE.sqlite3'"
  echo "[$DATE] database OK"
else
  echo "[$DATE] WARNING: $DB tidak ditemukan!" >&2
fi

# .env (kredensial & konfigurasi)
if [ -f /root/lnbits/.env ]; then
  cp /root/lnbits/.env "$BACKUP_DIR/env-$DATE.bak"
  chmod 600 "$BACKUP_DIR/env-$DATE.bak"
  echo "[$DATE] .env OK"
fi

# Bersihkan backup lebih tua dari retensi
find "$BACKUP_DIR" -name "database-*.sqlite3" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "env-*.bak" -mtime +$RETENTION_DAYS -delete

echo "[$DATE] Backup selesai. Isi $BACKUP_DIR:"
ls -lh "$BACKUP_DIR" | tail -5
