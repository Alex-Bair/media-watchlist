require 'bcrypt'

def valid_credentials?(username, password, user)
  encrypted_password = user["password"]

  !username.empty? &&
    user["name"] == username &&
    BCrypt::Password.new(encrypted_password) == password
end

def signed_in?
  !session[:user_id].nil?
end

def authenticate
  unless signed_in? || request.path_info == "/users/sign_in"
    session[:next_destination] = request.path_info
    redirect "/users/sign_in"
  end
end