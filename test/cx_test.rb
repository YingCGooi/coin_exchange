ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'
require 'yaml'

require_relative '../cx.rb'

Minitest::Reporters.use!

class CXTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    admin_data = { 
      "admin"=> {
          :password=>"$2a$10$XQq2o2l8zVCndc9Ol1MpI..T9ckk2quGlRRVdXFeKJ29ySnFkkH5W",
          :created=>"2017-11-03 22:08:11 -0500", 
          :balances=>{:btc_bal=>0, :eth_bal=>0, :usd_bal=>6320}, 
          :transactions=>[]
        }
      }

    File.write(user_data_file_path, admin_data.to_yaml)
  end

  def teardown
  end

  def session
    last_request.env['rack.session']
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_match /BUY AND SELL DIGITAL CURRENCIES/i, last_response.body
    assert_match /Sign In.+\s?.+Sign Up.+\s?.+View Charts/i, last_response.body
  end

  def test_chart
    historical_bpi = parse_api(HISTORICAL_BPI_API)

    get '/charts'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_match /Bitcoin Price: \$/, last_response.body

    historical_bpi['bpi'].each do |date, price|
      assert_includes last_response.body, date
      assert_includes last_response.body, price.to_s
    end

    assert_includes last_response.body, Time.now.year.to_s
  end

  def test_sign_up_page
    get '/signup'
    assert_equal 200, last_response.status
    [
      /<input type='text'.+placeholder='Username'/,
      /<input type='password'.+placeholder='Choose A Password/,
      /<button type='submit'>Create Account<\/button>/i
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_sign_up_success
    post '/user/signup', username: 'hello', password: '12345', agreed: 'true'
    assert_equal 302, last_response.status
    assert_equal "You have created a new account 'hello'.<br />Please sign-in to continue.", session[:success]

    user_data = YAML.load_file(user_data_file_path)
    assert_includes user_data, 'hello'
    assert user_data['hello'][:new_user]
  end

  def test_sign_up_error
    post '/user/signup', username: '', password: '', agreed: nil
    assert_equal 422, last_response.status
    [
      /Please enter a username/,
      /Password must contain a non-space character/,
      /Please accept the user agreement/
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end

    post '/user/signup', username: 'admin', password: '12345', agreed: 'true'
    assert_equal 422, last_response.status
    assert_match /Username 'admin' is unavailable/, last_response.body

    post '/user/signup', username: 'hello world', password: '123', agreed: 'true'
    [
      /Username must not contain spaces/,
      /Password too short/,
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end

    post '/user/signup', username: 'welcome', password: '12345', agreed: 'yes'
    assert_match /Please accept the user agreement/, last_response.body
  end

  def test_signin_page
    get '/signin'
    assert_equal 200, last_response.status
    [
      /<input type='text'.+placeholder='Username'/,
      /<input type='password'.+placeholder='Password'/,
      /<button type='submit'>Sign In<\/button>/i
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_signin_valid_credentials
    post '/user/signin', username: 'admin', password: 'secret'
    
  end
end