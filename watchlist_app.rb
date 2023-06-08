require "sinatra"
require "tilt/erubis"
require 'securerandom'
require "pry"

require_relative "lib/media"
require_relative "lib/watchlist"
require_relative "lib/database_persistence"
require_relative "lib/authentication_methods"
require_relative "lib/validation_methods"

DISPLAY_LIMIT = 5

def database_exists?(name)
  postgres_db = PG.connect(dbname: "postgres")

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
  create_database_file = File.expand_path("../lib/create_database.rb", __FILE__) 
  load create_database_file 
end

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] { SecureRandom.hex(64) }
  set :erb, :escape_html => true

  setup_database unless database_exists?('media_watchlist')
end

before do
  @storage = DatabasePersistence.new(logger)
  authenticate
  @user_id = session[:user_id]
end

# Validate watchlist_id and media_id URL parameters.

before "/watchlist/:watchlist_id*" do
  validate_watchlist_id(params[:watchlist_id], @user_id)
end

before "/watchlist/:watchlist_id/media/:media_id*" do
  validate_media_id(params[:media_id], params[:watchlist_id])
end

# Initialize and validate page numbers

ROUTES_WITH_PAGES = ["/", "/watchlist/:watchlist_id"]

before "/" do
  @max_page = @storage.max_watchlist_page_number(DISPLAY_LIMIT, @user_id).to_i
  validate_watchlist_page_number(params[:page], @max_page)
end

before "/watchlist/:watchlist_id" do
  @max_page = @storage.max_media_page_number(DISPLAY_LIMIT, params[:watchlist_id]).to_i
  validate_media_page_number(params[:page], @max_page)
end

ROUTES_WITH_PAGES.each do |route|
  before route do
    @page = nil_or_empty?(params[:page]) ? 1 : params[:page].to_i
    @offset = (@page - 1) * DISPLAY_LIMIT
  end
end

after do
  session[:previous_path] = request.path_info + "?" + request.query_string
end

# ROUTE HANDLING

# -- WATCHLIST RELATED ROUTES

# Display homepage with list of watchlists

get "/" do
  @watchlists = @storage.fetch_page_of_watchlists(@user_id, DISPLAY_LIMIT, @offset)

  erb :home
end

# Create a new watchlist

post "/" do
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

# View a watchlist

get "/watchlist/:watchlist_id" do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  erb :watchlist
end

# View page to rename a watchlist

get "/watchlist/:watchlist_id/rename" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)

  erb :rename_watchlist
end

# Rename a watchlist

post "/watchlist/:watchlist_id/rename" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  old_name = @watchlist.name
  new_name = format_input(params[:new_name])

  if valid_watchlist_name?(new_name) || new_name == old_name
    @storage.rename_watchlist(new_name, params[:watchlist_id], @user_id)
    session[:success] = "#{old_name} was renamed to #{new_name}." unless new_name == old_name
    redirect "/"
  else
    session[:error] = INVALID_WATCHLIST_NAME_MESSAGE
    status 422
    erb :rename_watchlist
  end
end

# Delete a watchlist

post "/watchlist/:watchlist_id/delete" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  name = @watchlist.name

  @storage.delete_watchlist(@watchlist.id, @user_id)

  session[:success] = "#{name} was deleted."
  redirect "/"
end

# -- MEDIA RELATED ROUTES

# Add media to a watchlist

post "/watchlist/:watchlist_id" do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  @m_name = format_input(params[:name])
  @m_platform = format_input(params[:platform])
  @m_url = format_input(params[:url])
  session[:error] = ""

  if !valid_media_name?(@m_name)
    @m_name = nil
    session[:error] << INVALID_MEDIA_NAME_MESSAGE
  end

  if !valid_platform?(@m_platform)
    @m_platform = nil
    session[:error] << INVALID_PLATFORM_MESSAGE
  end

  if !valid_url?(@m_url)
    @m_url = nil
    session[:error] << INVALID_URL_MESSAGE
  end

  if session[:error].empty? #Checks to make sure no error messages were added to the session.
    @storage.create_media(@m_name, @m_platform, @m_url, @watchlist.id)
    session[:success] = "#{@m_name} was added to #{@watchlist}."
    redirect "/watchlist/#{@watchlist.id}?page=#{@page}"
  else
    status 422
    erb :watchlist
  end
end

# Visit page to edit a media

get "/watchlist/:watchlist_id/media/:media_id/edit" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  @m_name, @m_platform, @m_url = @media.name, @media.platform, @media.url

  erb :edit_media
end

# Edit a media

post "/watchlist/:watchlist_id/media/:media_id/edit" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  @m_name = format_input(params[:name])
  @m_platform = format_input(params[:platform])
  @m_url = format_input(params[:url])
  session[:error] = ""

  if !valid_media_name?(@m_name)
    @m_name = @media.name
    session[:error] << INVALID_MEDIA_NAME_MESSAGE
  end

  if !valid_platform?(@m_platform)
    @m_platform = @media.platform
    session[:error] << INVALID_PLATFORM_MESSAGE
  end

  if !valid_url?(@m_url)
    @m_url = @media.url
    session[:error] << INVALID_URL_MESSAGE
  end

  if session[:error].empty? 
    @storage.edit_media(@m_name, @m_platform, @m_url, @media.id, @watchlist.id)
    session[:success] = "Update was successful."
    redirect "/watchlist/#{@watchlist.id}"
  else
    status 422
    erb :edit_media
  end
end

# Delete a media

post "/watchlist/:watchlist_id/media/:media_id/delete" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  media = @watchlist.fetch_media(params[:media_id].to_i)
  name = media.name

  @storage.delete_media(media.id, @watchlist.id)
  session[:success] = "#{name} was deleted."
  
  redirect "/watchlist/#{@watchlist.id}"
end

# -- USER RELATED ROUTES

# Display registration page

get "/users/register" do
  erb :register
end

# Create a new user

post "/users/register" do
  username = format_input(params[:username])
  password = params[:password]

  if valid_username?(username)
    @storage.create_user(username, encrypt_password(password))
    redirect "/users/sign_in"
  else
    status 422
    erb :register
  end
end

# Display sign in page

get "/users/sign_in" do
  if @user_id
    session[:error] = "You are already signed in."
    redirect session[:previous_path]
  end
  
  erb :sign_in
end

# Sign in a user

post "/users/sign_in" do
  username = format_input(params[:username])
  password = params[:password]

  user = @storage.fetch_user(username)

  if valid_credentials?(username, password, user)
    session[:success] = "Welcome #{user["name"]}!"
    session[:user_id] = user["id"].to_i
    redirect (session.delete(:next_destination) || "/")
  else
    session[:error] = "Invalid credentials."
    status 422
    erb :sign_in
  end
end

# Sign out a user

get "/users/sign_out" do
  sign_out

  redirect "/users/sign_in"
end