# frozen_string_literal: true

require 'sinatra'
require 'tilt/erubis'
require 'securerandom'
require 'pry' # REMOVE FROM FINAL

require_relative 'lib/media'
require_relative 'lib/watchlist'
require_relative 'lib/database_persistence'
require_relative 'lib/helper_methods'

DISPLAY_LIMIT = 5

configure do
  enable :sessions
  set :session_secret, "20a14eeaa8fdc4d73e8d460204b2b2c3411b4f21c4fa94a9f9d7e7688d498e4c11b13d48f958ea70447c3436d8f01e2b31a6cd98f055e137d3be18ada0b5e653"  # ENV['SESSION_SECRET'] { SecureRandom.hex(64) }
  set :erb, escape_html: true # does this work to avoid JS injection?

  setup_database unless database_exists?('media_watchlist')
end

# FILTERS

# Ensure user is signed in before viewing any pages.

before do
  @storage = DatabasePersistence.new(logger)
  authenticate
  @user_id = session[:user_id]
end

# Validate watchlist_id and media_id URL parameters.

before '/watchlist/:watchlist_id*' do
  validate_watchlist_id(params[:watchlist_id], @user_id)
end

before '/watchlist/:watchlist_id/media/:media_id*' do
  validate_media_id(params[:media_id], params[:watchlist_id])
end

# Initialize and validate page numbers

ROUTES_WITH_WATCHLIST_PAGES = ['/', '/new_watchlist'].freeze

ROUTES_WITH_MEDIA_PAGES = ['/watchlist/:watchlist_id', '/watchlist/:watchlist_id/new_media'].freeze

ROUTES_WITH_PAGES = ROUTES_WITH_WATCHLIST_PAGES + ROUTES_WITH_MEDIA_PAGES

ROUTES_WITH_WATCHLIST_PAGES.each do |route|
  before route do
    @max_page = @storage.max_watchlist_page_number(DISPLAY_LIMIT, @user_id).to_i
    validate_watchlist_page_number(params[:page], @max_page)
  end
end

ROUTES_WITH_MEDIA_PAGES.each do |route|
  before route do
    @max_page = @storage.max_media_page_number(DISPLAY_LIMIT, params[:watchlist_id]).to_i
    validate_media_page_number(params[:page], @max_page)
  end
end

ROUTES_WITH_PAGES.each do |route|
  before route do
    @page = nil_or_empty?(params[:page]) ? 1 : params[:page].to_i
    @offset = (@page - 1) * DISPLAY_LIMIT
  end
end

# Store previous path for possible redirects

after do
  session[:previous_path] = "#{request.path_info}?#{request.query_string}"
end

# ROUTES

# -- WATCHLIST RELATED ROUTES

# Display homepage with list of watchlists

get '/' do
  @watchlists = @storage.fetch_page_of_watchlists(@user_id, DISPLAY_LIMIT, @offset)

  erb :home
end

# Create a new watchlist

post '/new_watchlist' do
  name = format_input(params[:name])

  if valid_watchlist_name?(name)
    @storage.create_watchlist(name, @user_id)
    session[:success] = "#{name} was created."
    redirect "/?page=#{@page}"
  else
    @watchlists = @storage.fetch_page_of_watchlists(@user_id, DISPLAY_LIMIT, @offset)
    session[:error] = INVALID_WATCHLIST_NAME_MESSAGE
    status 422
    erb :home
  end
end

# Redirect to make "/new_watchlist" a valid path

get '/new_watchlist' do
  redirect "/?page=#{@page}"
end

# View a watchlist

get '/watchlist/:watchlist_id' do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  erb :watchlist
end

# View page to rename a watchlist

get '/watchlist/:watchlist_id/rename' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)

  erb :rename_watchlist
end

# Rename a watchlist

post '/watchlist/:watchlist_id/rename' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  old_name = @watchlist.name
  new_name = format_input(params[:new_name])

  if valid_watchlist_name?(new_name) || new_name == old_name
    @storage.rename_watchlist(new_name, params[:watchlist_id], @user_id)
    session[:success] = "#{old_name} was renamed to #{new_name}." unless new_name == old_name
    redirect '/'
  else
    session[:error] = INVALID_WATCHLIST_NAME_MESSAGE
    status 422
    erb :rename_watchlist
  end
end

# Delete a watchlist

post '/watchlist/:watchlist_id/delete' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  name = @watchlist.name

  @storage.delete_watchlist(@watchlist.id, @user_id)

  session[:success] = "#{name} was deleted."
  redirect '/'
end

# -- MEDIA RELATED ROUTES

# Add media to a watchlist

post '/watchlist/:watchlist_id/new_media' do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  initialize_m_ivars

  construct_error_if_invalid_media

  if session[:error].empty? # Checks to make sure no error messages were added to the session.
    @storage.create_media(@m_name, @m_platform, @m_url, @watchlist.id)
    session[:success] = "#{@m_name} was added to #{@watchlist}."
    redirect "/watchlist/#{@watchlist.id}?page=#{@page}"
  else
    status 422
    erb :watchlist
  end
end

# Redirect to make "/watchlist/:watchlist_id/new_media" a valid path

get '/watchlist/:watchlist_id/new_media' do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  redirect "/watchlist/#{@watchlist.id}?page=#{@page}"
end

# Visit page to edit a media

get '/watchlist/:watchlist_id/media/:media_id/edit' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  @m_name = @media.name
  @m_platform = @media.platform
  @m_url = @media.url

  erb :edit_media
end

# Edit a media

post '/watchlist/:watchlist_id/media/:media_id/edit' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  initialize_m_ivars

  construct_error_if_invalid_media(@media)

  if session[:error].empty?
    @storage.edit_media(@m_name, @m_platform, @m_url, @media.id, @watchlist.id)
    session[:success] = 'Update was successful.'
    redirect "/watchlist/#{@watchlist.id}"
  else
    status 422
    erb :edit_media
  end
end

# Delete a media

post '/watchlist/:watchlist_id/media/:media_id/delete' do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  media = @watchlist.fetch_media(params[:media_id].to_i)
  name = media.name

  @storage.delete_media(media.id, @watchlist.id)
  session[:success] = "#{name} was deleted."

  redirect "/watchlist/#{@watchlist.id}"
end

# -- USER RELATED ROUTES

# Display registration page

get '/users/register' do
  erb :register
end

# Create a new user

post '/users/register' do
  redirect_if_signed_in

  username = format_input(params[:username])
  password = params[:password]

  if valid_username?(username) && valid_password?(password)
    @storage.create_user(username, encrypt_password(password))
    session[:success] = 'Profile creation successful.'
    redirect '/users/sign_in'
  else
    status 422
    erb :register
  end
end

# Display sign in page

get '/users/sign_in' do
  redirect_if_signed_in

  erb :sign_in
end

# Sign in a user

post '/users/sign_in' do
  @username = format_input(params[:username])
  password = params[:password]

  user = @storage.fetch_user(@username)

  if valid_credentials?(@username, password, user)
    session[:success] = "Welcome, #{user['name']}!"
    session[:user_id] = user['id'].to_i
    redirect session.delete(:next_destination) || '/'
  else
    session[:error] = 'Invalid credentials.'
    status 422
    erb :sign_in
  end
end

# Sign out a user

get '/users/sign_out' do
  sign_out

  redirect '/users/sign_in'
end
