system 'dropdb media_watchlist'
system 'createdb media_watchlist'
system 'psql -d media_watchlist < db/schema.sql'
system 'psql -d media_watchlist < db/seed_data.sql'