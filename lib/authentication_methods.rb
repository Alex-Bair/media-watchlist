require 'bcrypt'

def valid_credentials?(username, password, user)
  !username.empty? &&
    !user.nil? &&
    BCrypt::Password.new(user["password"]) == password
end

def signed_in?
  !session[:user_id].nil?
end

def authenticate
  path = request.path_info

  unless ( signed_in? || 
      path == "/users/sign_in" || 
      path == "/users/register" )

    session[:next_destination] = request.path_info
    redirect "/users/sign_in"
  end
end

def encrypt_password(password)
  BCrypt::Password.create(password)
end

def sign_out
  session.delete(:user_id)
  session[:success] = "You have been signed out."
end