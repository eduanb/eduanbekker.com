#!/bin/sh

set -e

echo "Starting custom entrypoint..."

# Initialize the database but don't start postgres
docker-entrypoint.sh postgres -h '' &
PID=$!

# Wait for the initialization to complete
echo "Waiting for PostgreSQL to initialize..."
until pg_isready; do
    sleep 1
done

# Stop the temporary PostgreSQL process
echo "Stopping temporary PostgreSQL process..."
kill -s TERM $PID
wait $PID

# Modify the PostgreSQL configuration
echo "Modifying PostgreSQL configuration..."
echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.database_name = '${POSTGRES_DB:-postgres}'" >> /var/lib/postgresql/data/postgresql.conf

echo "Starting PostgreSQL..."
exec su - postgres -c "postgres -D /var/lib/postgresql/data"