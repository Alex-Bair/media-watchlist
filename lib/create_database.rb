# frozen_string_literal: true

# rubocop:disable Style/ExpandPathArguments
schema_path = File.expand_path('../../db/schema.sql', __FILE__)
# rubocop:enable Style/ExpandPathArguments

system 'createdb media_watchlist'
system "psql -d media_watchlist < #{schema_path}"
