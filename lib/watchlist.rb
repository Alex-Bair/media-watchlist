# frozen_string_literal: true

# Class encapsulates watchlist attributes, including associated media.
# Provides #each to easily iterate through media and #fetch_media to retrieve a specific Media object on the watchlist.
class Watchlist
  attr_reader :id, :name, :media_list

  def initialize(id, name, media_list)
    @id = id
    @name = name
    @media_list = media_list
  end

  def each(&block)
    @media_list.each { |media| block.call(media) }

    self
  end

  def fetch_media(media_id)
    @media_list.select do |media|
      media.id == media_id
    end.first
  end

  def to_s
    name
  end
end
