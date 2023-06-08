URL_REGEX = /https?:\/\/(www\.)?[a-z0-9]{1,}\.[a-z]{3}(\/[a-z0-9\-\_\%]*)*\?*([a-z0-9\-\_\%]*\=*[a-z0-9\-\_\%]*\&*)*/i
NUMBER_REGEX = /^\d+$/

NAME_CHAR_LIMIT = 60
PLATFORM_CHAR_LIMIT = 20

INVALID_WATCHLIST_NAME_MESSAGE = "Name must be unique and between 1 and #{NAME_CHAR_LIMIT} characters. "
INVALID_MEDIA_NAME_MESSAGE = "Name must be between 1 and #{NAME_CHAR_LIMIT} characters. "
INVALID_PLATFORM_MESSAGE = "Platform must be between 1 and #{PLATFORM_CHAR_LIMIT} characters. "
INVALID_URL_MESSAGE = "Invalid URL. "

def invalid_page_number_error(max, items)
  if max == 1
    "Invalid page number - there is only 1 page of #{items}."
  else
    "Invalid page number - there are only #{max} pages of #{items}."
  end
end

def nil_or_empty?(input)
  input.nil? || input.empty?
end

def format_input(string)
  string.strip
end

def all_whitespace?(string)
  string.strip.empty?
end

def shorter_than?(string, length)
  string.strip.size <= length
end

def valid_watchlist_name?(string)

  existing_names = @storage.all_watchlists(@user_id).map {|hsh| hsh[:name]}

  !all_whitespace?(string) && shorter_than?(string, NAME_CHAR_LIMIT) && !existing_names.include?(string)
end

def valid_media_name?(string)
  !all_whitespace?(string) && shorter_than?(string, NAME_CHAR_LIMIT)
end

def valid_platform?(string)
  !all_whitespace?(string) && shorter_than?(string, PLATFORM_CHAR_LIMIT)
end

def valid_url?(string)
  string.empty? || string.match?(URL_REGEX)
end

def valid_media?(name, platform, url)
  valid_name?(name) && valid_platform?(platform) && valid_url?(url)
end

def valid_watchlist_id?(watchlist_id, user_id)
  @storage.all_watchlist_ids(user_id).include?(watchlist_id)
end

def valid_media_id?(media_id, watchlist_id)
  @storage.all_media_ids(watchlist_id).include?(media_id)
end

def validate_watchlist_id(watchlist_id, user_id)
  unless valid_watchlist_id?(watchlist_id, user_id) || watchlist_id.nil?
    session[:error] = "That watchlist does not exist."
    redirect "/"
  end
end

def validate_media_id(media_id, watchlist_id)
  unless valid_media_id?(media_id, watchlist_id) || media_id.nil?
    session[:error] = "That media does not exist."
    redirect "/watchlist/#{watchlist_id}"
  end
end

def valid_page_number?(page_number_str, max)
  return true if nil_or_empty?(page_number_str)

  p_num = page_number_str.to_i

  page_number_str.match?(NUMBER_REGEX) &&
    p_num > 0 && 
    p_num <= max
end

def validate_watchlist_page_number(page_number, max)
  unless valid_page_number?(page_number, max)
    session[:error] = invalid_page_number_error(max, "watchlists")
    redirect "/"
  end
end

def validate_media_page_number(page_number, max)
  unless valid_page_number?(page_number, max)
    session[:error] = invalid_page_number_error(max, "media")
    redirect "/watchlist/#{params[:watchlist_id]}"
  end
end

def username_exists?(name)
  !@storage.fetch_user(name).nil?
end

def valid_username?(name)
  if username_exists?(name)
    session[:error] = "A profile already exists for user #{username}."
  elsif !shorter_than?(name, NAME_CHAR_LIMIT)
    session[:error] = "Username must be shorter than #{NAME_CHAR_LIMIT} characters."
  else
    session[:success] = "Profile creation successful."
    return true
  end

  false
end