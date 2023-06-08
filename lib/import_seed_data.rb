seed_data_path = File.expand_path("../../db/media_watchlist_dump.sql", __FILE__)

system "dropdb media_watchlist"
system "createdb media_watchlist"
system "psql -d media_watchlist < #{seed_data_path}"