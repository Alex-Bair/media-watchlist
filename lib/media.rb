# frozen_string_literal: true

# Class encapsulates media attributes
class Media
  attr_reader :id, :name, :platform, :url

  def initialize(id, name, platform, url)
    @id = id
    @name = name
    @platform = platform
    @url = url
  end

  def to_s
    name
  end
end
