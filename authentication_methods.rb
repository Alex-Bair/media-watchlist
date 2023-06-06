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
  unless ( signed_in? || 
      request.path_info == "/users/sign_in" || 
      request.path_info == "/users/register" )
    session[:next_destination] = request.path_info
    redirect "/users/sign_in"
  end
end

def encrypt_password(password)
  BCrypt::Password.create(password)
end