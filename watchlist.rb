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

  def to_s
    name
  end
end