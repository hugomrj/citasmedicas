#!/usr/bin/env bash
# Regenera schema.sql desde la DB actual (útil tras editar a mano con DB Browser)
cd "$(dirname "$0")/.."
sqlite3 db/citasmedicas.sqlite3 .schema > scripts/schema.sql
echo "✓ schema.sql regenerado desde la DB"