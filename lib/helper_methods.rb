# frozen_string_literal: true

# HELPER METHODS

require 'bcrypt'

# VALIDATION

URL_REGEX = %r{
  https?://                            # http or https
  (www\.)?                             # www.
  [a-z0-9]{1,}                         # domain
  \.[a-z]{3}                           # .com or any other 3 letters following a .
  (/[a-z0-9\-_%]*)*                    # optional path of any length
  \?*([a-z0-9\-_%]*=*[a-z0-9\-_%]*&*)* # optional query string of any length
}xi

NUMBER_REGEX = /^\d+$/

NAME_CHAR_LIMIT = 60
PLATFORM_CHAR_LIMIT = 20

INVALID_WATCHLIST_NAME_MESSAGE = "Name must be unique and between 1 and #{NAME_CHAR_LIMIT} characters. ".freeze
INVALID_MEDIA_NAME_MESSAGE = "Name must be between 1 and #{NAME_CHAR_LIMIT} characters. ".freeze
INVALID_PLATFORM_MESSAGE = "Platform must be between 1 and #{PLATFORM_CHAR_LIMIT} characters. ".freeze
INVALID_URL_MESSAGE = 'Invalid URL. '

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
  existing_names = @storage.all_watchlists(@user_id).map { |hsh| hsh[:name] }

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

def valid_watchlist_id?(watchlist_id, user_id)
  @storage.all_watchlist_ids(user_id).include?(watchlist_id)
end

def valid_media_id?(media_id, watchlist_id)
  @storage.all_media_ids(watchlist_id).include?(media_id)
end

def validate_watchlist_id(watchlist_id, user_id)
  return if valid_watchlist_id?(watchlist_id, user_id) || watchlist_id.nil?

  session[:error] = 'That watchlist does not exist.'
  redirect '/'
end

def validate_media_id(media_id, watchlist_id)
  return if valid_media_id?(media_id, watchlist_id) || media_id.nil?

  session[:error] = 'That media does not exist.'
  redirect "/watchlist/#{watchlist_id}"
end

def valid_page_number?(page_number_str, max)
  return true if nil_or_empty?(page_number_str)

  p_num = page_number_str.to_i

  page_number_str.match?(NUMBER_REGEX) &&
    p_num.positive? &&
    p_num <= max
end

def validate_watchlist_page_number(page_number, max)
  return if valid_page_number?(page_number, max)

  session[:error] = invalid_page_number_error(max, 'watchlists')
  redirect '/'
end

def validate_media_page_number(page_number, max)
  return if valid_page_number?(page_number, max)

  session[:error] = invalid_page_number_error(max, 'media')
  redirect "/watchlist/#{params[:watchlist_id]}"
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
    session[:success] = 'Profile creation successful.'
    return true
  end

  false
end

# AUTHENTICATION

def valid_credentials?(username, password, user)
  !username.empty? &&
    !user.nil? &&
    BCrypt::Password.new(user['password']) == password
end

def signed_in?
  !session[:user_id].nil?
end

def authenticate
  path = request.path_info

  unless signed_in? ||
         path == '/users/sign_in' ||
         path == '/users/register'

    session[:next_destination] = request.path_info
    redirect '/users/sign_in'
  end
end

def encrypt_password(password)
  BCrypt::Password.create(password)
end

def sign_out
  session.delete(:user_id)
  session[:success] = 'You have been signed out.'
end

# DATABASE SETUP

def database_exists?(name)
  postgres_db = PG.connect(dbname: 'postgres')

  sql = <<~SQL
    SELECT datname
    FROM pg_catalog.pg_database
    WHERE datname = $1;
  SQL

  result = postgres_db.exec_params(sql, [name])

  postgres_db.close

  result.ntuples == 1
end

def setup_database
  # rubocop:disable Style/ExpandPathArguments
  create_database_file = File.expand_path('../lib/create_database.rb', __FILE__)
  # rubocop:enable Style/ExpandPathArguments
  load create_database_file
end

# MEDIA RELATED ROUTE HELPERS

def initialize_m_ivars
  @m_name = format_input(params[:name])
  @m_platform = format_input(params[:platform])
  @m_url = format_input(params[:url])
end

def check_media_name(name)
  return if valid_media_name?(@m_name)

  @m_name = name
  session[:error] << INVALID_MEDIA_NAME_MESSAGE
end

def check_media_platform(platform)
  return if valid_platform?(@m_platform)

  @m_platform = platform
  session[:error] << INVALID_PLATFORM_MESSAGE
end

def check_media_url(url)
  return if valid_url?(@m_url)

  @m_url = url
  session[:error] << INVALID_URL_MESSAGE
end

def check_media_inputs(default)
  check_media_name(default.name)

  check_media_platform(default.platform)

  check_media_url(default.url)
end

def construct_error_if_invalid_media(default = nil)
  default ||= Media.new(nil, nil, nil, nil)

  session[:error] = +''

  check_media_inputs(default)
end
