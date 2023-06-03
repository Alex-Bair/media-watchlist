class Watchlist
  attr_reader :id, :name, :media_list

  def initialize(id, name, media_list)
    @id = id
    @name = name
    @media_list = media_list
  end

  def each
    @media_list.each { |media| yield(media) }

    self
  end

  def size
    @media_list.size
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