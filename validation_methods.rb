URL_REGEX = /https?:\/\/(www\.)?[a-z0-9]{1,}\.[a-z]{3}(\/[a-z0-9\-\_\%]*)*\?*([a-z0-9\-\_\%]*\=*[a-z0-9\-\_\%]*\&*)*/i

NAME_CHAR_LIMIT = 50
PLATFORM_CHAR_LIMIT = 20

INVALID_NAME_MESSAGE = "Name must be between 1 and #{NAME_CHAR_LIMIT} characters."
INVALID_PLATFORM_MESSAGE = "Platform must be between 1 and #{PLATFORM_CHAR_LIMIT} characters."
INVALID_URL_MESSAGE = "Invalid URL."


def format_input(string)
  string.strip
end

def all_whitespace?(string)
  string.strip.empty?
end

def shorter_than?(string, length)
  string.strip.size <= length
end

def valid_name?(string)
  !all_whitespace?(string) && shorter_than?(string, NAME_CHAR_LIMIT)
end

def valid_platform?
  !all_whitespace?(string) && shorter_than?(string, PLATFORM_CHAR_LIMIT)
end

def valid_url?
  string.empty? || string.match?(URL_REGEX)
end

def valid_media?(name, platform, url)
  valid_name?(name) && valid_platform?(platform) && valid_url?(url)
end

def valid_watchlist_id?(watchlist_id, user_id)
  all_watchlist_ids(user_id).include?(watchlist_id)
end

def valid_media_id?(media_id, watchlist_id, user_id)
  all_media_ids(watchlist_id, user_id).include?(media_id)
end