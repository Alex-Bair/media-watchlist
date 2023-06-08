# frozen_string_literal: true

require 'pg'
# rubocop: disable Metrics/ClassLength
# Class encapsulates interactions with the media_watchlist database
class DatabasePersistence
  def initialize(logger)
    @database = PG.connect(dbname: 'media_watchlist')
    @logger = logger
  end

  # USER RELATED INTERFACE

  def create_user(name, password)
    sql = 'INSERT INTO users (name, password) VALUES ($1, $2);'

    query(sql, name, password)
  end

  def fetch_user(name)
    sql = <<~SQL
      SELECT *
        FROM users
       WHERE name = $1;
    SQL

    result = query(sql, name)
    result.select do |tuple|
      name == tuple['name']
    end.first
  end

  # WATCHLIST RELATED INTERFACE

  def max_watchlist_page_number(items_per_page, user_id)
    sql = <<~SQL
      SELECT CEIL(COUNT(id) * 1.0 / $1) AS max_page
        FROM watchlists
       WHERE user_id = $2;
    SQL

    result = query(sql, items_per_page, user_id).field_values('max_page').first

    result = '1' if result == '0'

    result
  end

  def all_watchlist_ids(user_id)
    sql = 'SELECT id FROM watchlists WHERE user_id = $1;'
    result = query(sql, user_id)
    result.field_values('id')
  end

  # rubocop:disable Metrics/MethodLength, Layout/HeredocIndentation

  def fetch_page_of_watchlists(user_id, limit, offset)
    sql = <<~SQL
               SELECT w.id,
                      w.name,
                      w.user_id,
                      COUNT(m.id) AS media_count
                 FROM watchlists AS w
      LEFT OUTER JOIN media AS m
                   ON m.watchlist_id = w.id
                WHERE w.user_id = $1
             GROUP BY w.id
             ORDER BY w.id
                LIMIT $2
               OFFSET $3;
    SQL

    result = query(sql, user_id, limit, offset)

    tuple_to_hash_of_watchlists(result)
  end

  def all_watchlists(user_id)
    sql = <<~SQL
               SELECT w.id,
                      w.name,
                      w.user_id,
                      COUNT(m.id) AS media_count
                 FROM watchlists AS w
      LEFT OUTER JOIN media AS m
                   ON m.watchlist_id = w.id
                WHERE w.user_id = $1
             GROUP BY w.id
             ORDER BY w.id;
    SQL

    result = query(sql, user_id)

    tuple_to_hash_of_watchlists(result)
  end

  def fetch_partial_watchlist(watchlist_id, user_id, limit, offset)
    sql = <<~SQL
              SELECT w.id AS watchlist_id,
                     w.name AS watchlist_name,
                     m.id AS media_id,
                     m.name AS media_name,
                     m.platform,
                     m.url
                FROM watchlists AS w
     LEFT OUTER JOIN media AS m
                  ON w.id = m.watchlist_id
               WHERE w.id = $1 AND w.user_id = $2
            ORDER BY m.id
               LIMIT $3
              OFFSET $4;
    SQL

    result = query(sql, watchlist_id, user_id, limit, offset)

    tuple_to_watchlist(result)
  end

  def fetch_full_watchlist(watchlist_id, user_id)
    sql = <<~SQL
              SELECT w.id AS watchlist_id,
                     w.name AS watchlist_name,
                     m.id AS media_id,
                     m.name AS media_name,
                     m.platform,
                     m.url
                FROM watchlists AS w
     LEFT OUTER JOIN media AS m
                  ON w.id = m.watchlist_id
               WHERE w.id = $1 AND w.user_id = $2
            ORDER BY m.id;
    SQL

    result = query(sql, watchlist_id, user_id)

    tuple_to_watchlist(result)
  end
  # rubocop:enable Metrics/MethodLength, Layout/HeredocIndentation

  def create_watchlist(name, user_id)
    sql = 'INSERT INTO watchlists (name, user_id) VALUES ($1, $2);'

    query(sql, name, user_id)
  end

  def rename_watchlist(new_name, watchlist_id, user_id)
    sql = <<~SQL
      UPDATE watchlists
         SET name = $1
       WHERE id = $2 AND user_id = $3;
    SQL

    query(sql, new_name, watchlist_id, user_id)
  end

  def delete_watchlist(watchlist_id, user_id)
    sql = <<~SQL
      DELETE FROM watchlists
      WHERE id = $1 AND user_id = $2;
    SQL

    query(sql, watchlist_id, user_id)
  end

  # MEDIA RELATED INTERFACE

  def max_media_page_number(items_per_page, watchlist_id)
    sql = <<~SQL
      SELECT CEIL(COUNT(id) * 1.0 / $1) AS max_page
      FROM media
      WHERE watchlist_id = $2;
    SQL

    query(sql, items_per_page, watchlist_id).field_values('max_page').first
  end

  def all_media_ids(watchlist_id)
    sql = 'SELECT id FROM media WHERE watchlist_id = $1;'
    result = query(sql, watchlist_id)
    result.field_values('id')
  end

  def fetch_media(media_id, watchlist_id)
    sql = 'SELECT * FROM media WHERE id = $1 AND watchlist_id = $2;'

    result = query(sql, [media_id, watchlist_id])

    result.map { |tuple| tuple_to_media(tuple) }.first
  end

  def create_media(name, platform, url, watchlist_id)
    sql = 'INSERT INTO media (name, platform, url, watchlist_id) VALUES ($1, $2, $3, $4);'

    query(sql, name, platform, url, watchlist_id)
  end

  def edit_media(new_name, new_platform, new_url, media_id, watchlist_id)
    sql = <<~SQL
      UPDATE media
         SET name = $1,
             platform = $2,
             url = $3
       WHERE id = $4 AND watchlist_id = $5;
    SQL

    query(sql, new_name, new_platform, new_url, media_id, watchlist_id)
  end

  def delete_media(media_id, watchlist_id)
    sql = 'DELETE FROM media WHERE id = $1 AND watchlist_id = $2'

    query(sql, media_id, watchlist_id)
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @database.exec_params(statement, params)
  end

  def tuple_to_hash_of_watchlists(result)
    result.map do |tuple|
      { id: tuple['id'].to_i,
        name: tuple['name'],
        media_count: tuple['media_count'] }
    end
  end

  def tuple_to_watchlist(result)
    media_list = []

    result.each do |tuple|
      # Must factor out nil result if watchlist does not contain any media yet
      media_list << tuple_to_media(tuple) unless tuple['media_id'].nil?
    end

    watchlist_id = result.field_values('watchlist_id').first
    watchlist_name = result.field_values('watchlist_name').first

    Watchlist.new(watchlist_id, watchlist_name, media_list)
  end

  def tuple_to_media(tuple)
    Media.new(tuple['media_id'].to_i, tuple['media_name'], tuple['platform'], tuple['url'])
  end
end
# rubocop:enable Metrics/ClassLength
