require "sinatra"
require "tilt/erubis"
require "pry"

require_relative "media"
require_relative "watchlist"
require_relative "database_persistence"
require_relative "authentication_methods"
require_relative "validation_methods"

DISPLAY_LIMIT = 5

configure do
  enable :sessions
  # may need to set the session secret
  set :erb, :escape_html => true

  # does starting postgresql and setting up the database go in here?
end

configure(:development) do
  require "sinatra/reloader"
end

def nil_or_empty?(input)
  input.nil? || input.empty?
end

before do
  @storage = DatabasePersistence.new(logger)
  authenticate
  @user_id = session[:user_id]
end

# Validate watchlist_id and media_id URL parameters.

before  "/watchlist/:watchlist_id*" do
  validate_watchlist_id(params[:watchlist_id], @user_id)
end

before "/watchlist/:watchlist_id/media/:media_id*" do
  validate_media_id(params[:media_id], params[:watchlist_id])
end

# Initialize and validate page numbers

before "/" do
  @max_page = @storage.max_watchlist_page_number(DISPLAY_LIMIT, @user_id).to_i
  validate_watchlist_page_number(params[:page], @max_page)
  @page = nil_or_empty?(params[:page]) ? 1 : params[:page].to_i
  @offset = (@page - 1) * DISPLAY_LIMIT
end

before "/watchlist/:watchlist_id" do
  @max_page = @storage.max_media_page_number(DISPLAY_LIMIT, params[:watchlist_id]).to_i
  validate_media_page_number(params[:page], @max_page)
  @page = nil_or_empty?(params[:page]) ? 1 : params[:page].to_i
  @offset = (@page - 1) * DISPLAY_LIMIT
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

  if valid_name?(name) # need to ensure name is unique
    @storage.create_watchlist(name, @user_id)
    session[:message] = "#{name} was created."
    redirect "/?page=#{@page}"
  else
    @watchlists = @storage.fetch_page_of_watchlists(@user_id, DISPLAY_LIMIT, @offset)
    session[:message] = INVALID_NAME_MESSAGE
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

  if valid_name?(new_name)
    @storage.rename_watchlist(new_name, params[:watchlist_id], @user_id)
    session[:message] = "#{old_name} was renamed to #{new_name}."
    redirect "/"
  else
    session[:message] = INVALID_NAME_MESSAGE
    erb :rename_watchlist
  end
end

# Delete a watchlist

post "/watchlist/:watchlist_id/delete" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  name = @watchlist.name

  @storage.delete_watchlist(@watchlist.id, @user_id)

  session[:message] = "#{name} was deleted."
  redirect "/"
end

# -- MEDIA RELATED ROUTES

# Add media to a watchlist

post "/watchlist/:watchlist_id" do
  @watchlist = @storage.fetch_partial_watchlist(params[:watchlist_id], @user_id, DISPLAY_LIMIT, @offset)

  @m_name = format_input(params[:name])
  @m_platform = format_input(params[:platform])
  @m_url = format_input(params[:url])
  session[:message] = ""

  if !valid_name?(@m_name)
    @m_name = nil
    session[:message] << INVALID_NAME_MESSAGE
  end

  if !valid_platform?(@m_platform)
    @m_platform = nil
    session[:message] << INVALID_PLATFORM_MESSAGE
  end

  if !valid_url?(@m_url)
    @m_url = nil
    session[:message] << INVALID_URL_MESSAGE
  end

  if session[:message].empty? #Checks to make sure no error messages were added to the session.
    @storage.create_media(@m_name, @m_platform, @m_url, @watchlist.id)
    session[:message] = "#{@m_name} was added to #{@watchlist}."
    redirect "/watchlist/#{@watchlist.id}?page=#{@page}"
  else
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
  session[:message] = ""

  if !valid_name?(@m_name)
    @m_name = @media.name
    session[:message] << INVALID_NAME_MESSAGE
  end

  if !valid_platform?(@m_platform)
    @m_platform = @media.platform
    session[:message] << INVALID_PLATFORM_MESSAGE
  end

  if !valid_url?(@m_url)
    @m_url = @media.url
    session[:message] << INVALID_URL_MESSAGE
  end

  if session[:message].empty? 
    @storage.edit_media(@m_name, @m_platform, @m_url, @media.id, @watchlist.id)
    session[:message] = "Update was successful."
    redirect "/watchlist/#{@watchlist.id}"
  else
    erb :edit_media
  end
end

# Delete a media

post "/watchlist/:watchlist_id/media/:media_id/delete" do
  @watchlist = @storage.fetch_full_watchlist(params[:watchlist_id], @user_id)
  media = @watchlist.fetch_media(params[:media_id].to_i)
  name = media.name

  @storage.delete_media(media.id, @watchlist.id)
  session[:message] = "#{name} was deleted."
  
  redirect "/watchlist/#{@watchlist.id}"
end

# -- USER RELATED ROUTES

# Display registration page

# Create a new user

# Display sign in page

get "/users/sign_in" do
  erb :sign_in
end

# Sign in a user

post "/users/sign_in" do
  username = format_input(params[:username])
  password = params[:password]

  user = @storage.fetch_user(username)

  if valid_credentials?(username, password, user)
    session[:message] = "Welcome #{user["name"]}!"
    session[:user_id] = user["id"].to_i
    redirect (session.delete(:next_destination) || "/")
  else
    session[:message] = "Invalid credentials."
    status 422 # Should this be 401 instead?
    erb :sign_in
  end
end