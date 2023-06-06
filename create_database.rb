system 'dropdb media_watchlist'
system 'createdb media_watchlist'
system 'psql -d media_watchlist < schema.sql'
system 'psql -d media_watchlist < seed_data.sql'