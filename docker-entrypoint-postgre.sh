#!/bin/sh
set -e

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initialisation de la base de données PostgreSQL..."

    echo "$POSTGRES_PASSWORD" > /tmp/pwfile
    initdb -D "$PGDATA" --username=postgres --pwfile=/tmp/pwfile
    rm /tmp/pwfile

    pg_ctl -D "$PGDATA" -w start

    psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        CREATE USER "$POSTGRES_USER" WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';
        CREATE DATABASE "$POSTGRES_DB" OWNER "$POSTGRES_USER";
EOSQL

    pg_ctl -D "$PGDATA" -w stop

    echo "Initialisation terminée."
fi

exec postgres -D "$PGDATA"