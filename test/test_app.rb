ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env['rack.session']
  end

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

  def import_seed_data
    # rubocop:disable Style/ExpandPathArguments
    seed_data_path = File.expand_path('../../db/media_watchlist_dump.sql', __FILE__)
    # rubocop:enable Style/ExpandPathArguments

    system "psql -d media_watchlist < #{seed_data_path} > /dev/null 2>&1"
  end

  def admin_session
    { "rack.session" => {user_id: 1} }
  end

  def setup
    system 'createdb media_watchlist' unless database_exists?('media_watchlist')
    import_seed_data
    @database = DatabasePersistence.new
  end

  def teardown
    @database.drop_tables
    @database.close
  end

  def test_home_logged_out
    get "/"

    assert_equal(302, last_response.status)
    assert_equal('/', session[:next_destination])

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Please sign in to continue.')
    assert_includes(last_response.body, 'Register a new account.')
  end

  def test_home
    get '/', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Sign out')
    assert_includes(last_response.body, 'Fitness')
    assert_includes(last_response.body, 'Music')
    assert_includes(last_response.body, 'Next Page</a>')
    assert_includes(last_response.body, '>Create watchlist')
  end

  def test_home_error_invalid_page_number
    get '/', {page: 100}, admin_session

    assert_equal(302, last_response.status)
    assert_includes(session[:error], 'Invalid page number - there are only 3 pages of watchlists')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')
  end

  def test_create_watchlist
    get '/?page=3', {}, admin_session

    assert_equal(200, last_response.status)
    refute_includes(last_response.body, 'Test Watchlist')

    post '/new_watchlist?page=3', {name: 'Test Watchlist'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Test Watchlist was created.')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Test Watchlist</a>')
  end

  def test_rename_watchlist_page
    get '/watchlist/1/rename', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '>Rename Watchlist<')
    assert_includes(last_response.body, '>New name for Fitness:')
  end

  def test_rename_watchlist
    get '/', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')

    post '/watchlist/1/rename', {new_name: 'Test Watchlist'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Fitness was renamed to Test Watchlist')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Test Watchlist</a>')
  end

  def test_rename_watchlist_error_non_unique_name
    get '/', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')

    post '/watchlist/1/rename', {new_name: 'Music'}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Name must be unique and between 1 and')
  end

  def test_rename_watchlist_error_empty_name
    get '/', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')

    post '/watchlist/1/rename', {new_name: '  '}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Name must be unique and between 1 and')
  end

  def test_delete_watchlist
    get '/', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')

    post '/watchlist/1/delete'
    
    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Fitness was deleted.')

    get last_response['Location']

    assert_equal(200, last_response.status)
    refute_includes(last_response.body, 'Fitness</a>')
  end

  def test_view_watchlist
    get '/watchlist/2', {page: 2}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Moonlight Serendipity')
    assert_includes(last_response.body, 'Previous Page')
    assert_includes(last_response.body, 'Next Page')
    assert_includes(last_response.body, 'Add a media:')
    assert_includes(last_response.body, '<form')
  end

  def test_view_watchlist_fewer_than_6_media
    get '/watchlist/1', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Protein Bar Review - LBP')
    refute_includes(last_response.body, 'Previous Page')
    refute_includes(last_response.body, 'Next Page')
  end

  def test_view_watchlist_first_page
    get '/watchlist/2', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'FFXIV OST - Athena')
    refute_includes(last_response.body, 'Previous Page')
    assert_includes(last_response.body, 'Next Page')
  end

  def test_view_watchlist_last_page
    get '/watchlist/2', {page: 5}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Smile Bomb')
    assert_includes(last_response.body, 'Previous Page')
    refute_includes(last_response.body, 'Next Page')
  end

  def test_view_watchlist_error_invalid_id
    get '/watchlist/500', {}, admin_session

    assert_equal(302, last_response.status)
    assert_includes(session[:error], 'That watchlist does not exist')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Fitness')
  end

  def test_view_watchlist_error_invalid_page_number
    get '/watchlist/1', {page: 50}, admin_session

    assert_equal(302, last_response.status)
    assert_includes(session[:error], 'Invalid page number - there is only 1 page of media')
  end

  def test_add_media
    get '/watchlist/1', {}, admin_session

    assert_equal(200, last_response.status)
    refute_equal(last_response.body, 'valid_name')

    post '/watchlist/1/new_media', { name: 'valid_name',
                                     platform: 'valid_platform',
                                     url: 'https://www.validurl.com' }

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'valid_name was added to Fitness')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'valid_name</a>')
  end

  def test_add_media_error_invalid_name
    post '/watchlist/1/new_media', { name: '   ',
                                     platform: 'valid_platform',
                                     url: 'https://www.validurl.com' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Name must be between 1 and ')
    assert_includes(last_response.body, 'valid_platform')
    assert_includes(last_response.body, 'https://www.validurl.com')
  end

  def test_add_media_error_invalid_platform
    post '/watchlist/1/new_media', { name: 'valid_name',
                                     platform: '   ',
                                     url: 'https://www.validurl.com' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Platform must be between 1 and ')
    assert_includes(last_response.body, 'valid_name')
    assert_includes(last_response.body, 'https://www.validurl.com')
  end

  def test_add_media_error_invalid_url
    post '/watchlist/1/new_media', { name: 'valid_name',
                                     platform: 'valid_platform',
                                     url: 'bad url' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Invalid URL')
  end

  def test_add_media_error_invalid_name_platform_url
    post '/watchlist/1/new_media', { name: '   ',
                                     platform: '  ',
                                     url: 'bad url' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Name must be between 1 and ')
    assert_includes(last_response.body, 'Platform must be between 1 and ')
    assert_includes(last_response.body, 'Invalid URL')
  end

  def test_delete_media
    get '/watchlist/1', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Protein Bar Review - LBP</a>')

    post '/watchlist/1/media/2/delete'

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Protein Bar Review - LBP was deleted')

    get last_response['Location']

    assert_equal(200, last_response.status)
    refute_includes(last_response.body, 'Protein Bar Review - LBP</a>')
  end

  def test_edit_media_page
    get '/watchlist/1/media/2/edit', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Protein Bar Review - LBP</h2>')
    assert_includes(last_response.body, '<form')
    assert_includes(last_response.body, 'Edit media</button>')
  end

  def test_edit_media
    get '/watchlist/1', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Protein Bar Review - LBP')

    post '/watchlist/1/media/2/edit', {name: 'valid_name', platform: 'valid_platform', url: 'https://www.validurl.com'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Update was successful')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'valid_name')
    refute_includes(last_response.body, 'Protein Bar Review - LBP</a>')
  end

  def test_edit_media_error_invalid_name
    post '/watchlist/1/media/2/edit', { name: '  ',
                                        platform: 'valid_platform',
                                        url: 'https://www.validurl.com' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Name must be between 1 and ')
    assert_includes(last_response.body, 'valid_platform')
    assert_includes(last_response.body, 'https://www.validurl.com')
  end

  def test_edit_media_error_invalid_platform
    post '/watchlist/1/media/2/edit', { name: 'valid_name',
                                        platform: '   ',
                                        url: 'https://www.validurl.com' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Platform must be between 1 and ')
    assert_includes(last_response.body, 'valid_name')
    assert_includes(last_response.body, 'https://www.validurl.com')
  end

  def test_edit_media_error_invalid_url
    post '/watchlist/1/media/2/edit', { name: 'valid_name',
                                        platform: 'valid_platform',
                                        url: 'bad url' }, admin_session

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Invalid URL')
    assert_includes(last_response.body, 'valid_name')
    assert_includes(last_response.body, 'valid_platform')
  end

  def test_sign_in_page
    get '/users/sign_in'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Please sign in to continue')
    assert_includes(last_response.body, 'Sign in</button>')
    assert_includes(last_response.body, 'Register a new account.</a>')
  end

  def test_sign_in
    post '/users/sign_in', {username: 'admin', password: 'supersecret'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Welcome, admin!')
    assert_equal(session[:user_id], 1)

    get last_response['Location']

    assert_equal(200, last_response.status)
  end

  def test_sign_in_error
    post '/users/sign_in', {username: 'admin', password: 'incorrect_password'}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Invalid credentials')
    assert_includes(last_response.body, 'admin')
  end

  def test_sign_out
    get '/users/sign_out', {}, admin_session

    assert_equal(302, last_response.status)
    assert_nil(session[:user_id])
    assert_includes(session[:success], 'You have been signed out.')

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Please sign in to continue')

    get '/'
    assert_equal(302, last_response.status)
    assert_includes(last_response['Location'], '/users/sign_in')
  end

  def test_register_user_page
    get '/users/register'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Please create a profile')
    assert_includes(last_response.body, 'Register</button>')
    assert_includes(last_response.body, '<p>Already have an account?')
  end

  def test_register_user
    post '/users/register', {username: 'new_user', password: 'new_password'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Profile creation successful')

    get last_response['Location']

    assert_equal(200, last_response.status)

    post '/users/sign_in', {username: 'new_user', password: 'new_password'}

    assert_equal(302, last_response.status)
    assert_includes(session[:success], 'Welcome, new_user!')
    assert_equal(session[:user_id], 2)
  end

  def test_register_user_error_username_already_exists
    post '/users/register', {username: 'admin', password: 'new_password'}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'A profile already exists for user admin')
  end

  def test_register_user_error_invalid_username
    post '/users/register', {username: '    ', password: 'new_password'}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Username must be between 1 and ')
  end

  def test_register_user_error_invalid_password
    post '/users/register', {username: 'new_user', password: 'a'}

    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'Password must be at least ')
  end
end