#!/bin/bash
set -e

# Start PostgreSQL service directly
service postgresql start

# Wait for PostgreSQL to be ready  
until pg_isready -h localhost -p 5432 2>/dev/null; do
  echo "Waiting for PostgreSQL..."
  sleep 1
done

echo "PostgreSQL is ready!"

foreman start -f /rails/Procfile.regression