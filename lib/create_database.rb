schema_path = File.expand_path("../../db/schema.sql", __FILE__)

system "createdb media_watchlist"
system "psql -d media_watchlist < #{schema_path}"