#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	INSERT INTO users (username, password_hash, authority) VALUES ('$ADMIN_USERNAME', '$ADMIN_USER_HASH', 9999);
EOSQL
