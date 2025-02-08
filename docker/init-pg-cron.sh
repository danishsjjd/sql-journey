#!/bin/bash
set -e

# Add pg_cron to shared_preload_libraries
echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.database_name = 'mydb'" >> /var/lib/postgresql/data/postgresql.conf