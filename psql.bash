# Connect to PostgreSQL database using connection string
# psql "postgresql://username:password@host:port/database_name"
# OR:  psql -U postgres -h pg -d brain

# List all tables in the current database
\dt

# List all databases
\l

# Connect to a specific database
\c database_name

# Describe a table structure
\d table_name

# List all schemas
\dn

# List all users/roles
\du

# List all views
\dv

# Show command history
\s

# Execute commands from a file
\i filename.sql

# Export query results to a file
\o output_file.txt

# Clear the screen
\! clear

# Get help on SQL commands
\h

# Get help on psql commands
\?

# Quit psql
\q

# Timing of queries
\timing

# Show current connection info
\conninfo

# Execute previous command
\g


