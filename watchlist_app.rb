require "sinatra"
require "tilt/erubis"
require "pry"

require_relative "media"
require_relative "watchlist"
require_relative "database_persistence"
require_relative "authentication_methods"

configure do
  enable :sessions
  # may need to set the session secret
  set :erb, :escape_html => true
  
  # does starting postgresql and setting up the database go in here?
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
  authenticate
  # authenticate user is logged in
  @user_id = 1 # set user_id as instance variable based on logged in status
end


# ROUTE HANDLING

# -- WATCHLIST RELATED ROUTES

# Display homepage with list of watchlists

get "/" do
  @watchlists = @storage.all_watchlists(@user_id)

  erb :home
end

# Create a new watchlist

post "/new_watchlist" do
  name = params[:name]

  @storage.create_watchlist(name, @user_id)
  session[:mesasge] = "#{name} was created."
  redirect "/"
end

# View a watchlist

get "/watchlist/:watchlist_id" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)

  binding.pry

  erb :watchlist
end

# View page to rename a watchlist

get "/watchlist/:watchlist_id/rename" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)

  erb :rename_watchlist
end

# Rename a watchlist

post "/watchlist/:watchlist_id/rename" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  old_name = @watchlist.name
  new_name = params[:new_name]

  @storage.rename_watchlist(new_name, params[:watchlist_id], @user_id)

  session[:message] = "#{old_name} was renamed to #{new_name}."
  redirect "/"
end

# Delete a watchlist

post "/watchlist/:watchlist_id/delete" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  name = @watchlist.name

  @storage.delete_watchlist(@watchlist.id, @user_id)

  session[:message] = "#{name} was deleted."
  redirect "/"
end

# -- MEDIA RELATED ROUTES

# Add media to a watchlist

post "/watchlist/:watchlist_id/media/new" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  
  m_name = params[:name]
  m_platform = params[:platform]
  m_url = params[:url]

  @storage.create_media(m_name, m_platform, m_url, @watchlist.id)

  session[:message] = "#{m_name} was added to #{@watchlist}"

  redirect "/watchlist/#{@watchlist.id}"
end

# Visit page to edit a media

get "/watchlist/:watchlist_id/media/:media_id/edit" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  erb :edit_media
end

# Edit a media

post "/watchlist/:watchlist_id/media/:media_id/edit" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  @media = @watchlist.fetch_media(params[:media_id].to_i)

  m_name = params[:name]
  m_platform = params[:platform]
  m_url = params[:url]

  @storage.edit_media(m_name, m_platform, m_url, @media.id, @watchlist.id)

  session[:message] = "Update was successful."

  redirect "/watchlist/#{@watchlist.id}"
end

# Delete a media

post "/watchlist/:watchlist_id/media/:media_id/delete" do
  @watchlist = @storage.fetch_watchlist(params[:watchlist_id], @user_id)
  media = @watchlist.fetch_media(params[:media_id].to_i)
  name = media.name

  @storage.delete_media(media.id, @watchlist.id)
  session[:message] = "#{name} was deleted."
  
  redirect "/watchlist/#{@watchlist.id}"
end

# -- USER RELATED ROUTES

# Display registration page

# Create a new user

# Display edit user page

# Edit user

# Display sign in page

get "/users/sign_in" do
  erb :sign_in
end

# Sign in a user

post "/users/sign_in" do
  username = params[:username].strip
  password = params[:password]

  user = @storage.fetch_user(username)

  if valid_credentials?(username, password, user)
    session[:message] = "Welcome!"
    session[:signed_in_account] = user
    redirect (session.delete(:next_destination) || "/")
  else
    session[:message] = "Invalid credentials."
    status 422 # Should this be 401 instead?
    erb :sign_in
  end
end