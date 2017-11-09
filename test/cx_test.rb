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

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { "rack.session" => { signin: { username: "admin", time: Time.now } } }
  end

  def setup
    Dir.chdir(ROOT)

    admin_data = { 
      "admin"=> {
          :password=>"$2a$10$XQq2o2l8zVCndc9Ol1MpI..T9ckk2quGlRRVdXFeKJ29ySnFkkH5W",
          :created=>"2017-11-03 22:08:11 -0500", 
          :balances=>{:btc=>0.987, :eth=>2.896, :usd=>6320}, 
          :transactions=>[]
        }
      }

    File.write(user_data_file_path, admin_data.to_yaml)
  end

  def teardown
    session.delete(:signin) if session[:signin]
  end

  def format_number(num)
    whole, decimal = format('%.2f', num).split('.')
    comma_sliced = whole.reverse.scan(/\d{3}|\d+/).join(',').reverse
    comma_sliced + '.' + decimal
  end

  def read_users_data_yml
    YAML.load_file(user_data_file_path)
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    [
      /BUY AND SELL DIGITAL COINS/i,
      /Sign In/,
      /Sign Up/,
      /View Charts/
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_chart
    skip
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

  def test_signup_page
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

  def test_signup_success
    post '/user/signup', username: 'hello', password: '12345', agreed: 'true'
    assert_equal 302, last_response.status
    assert_equal "You have created a new account 'hello'.<br />Please sign-in to continue.", session[:success]
    refute session[:signin]

    user_data = YAML.load_file(user_data_file_path)
    assert_includes user_data, 'hello'
    assert user_data['hello'][:new_user]

    assert_match /\/signin$/, last_response.location
  end

  def test_signup_error
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
    assert_equal 302, last_response.status
    assert_match /You have successfully signed in as 'admin'./, session[:success]
    assert_equal Time.now.to_s, session[:signin][:time].to_s
    assert_equal 'admin', session[:signin][:username]

    assert_match /\/dashboard$/, last_response.location
  end

  def test_signin_invalid_credentials
    post '/user/signin', username: 'hello', password: 'secret'
    assert_equal 422, last_response.status
    assert_match /Invalid credentials/, last_response.body
    refute session[:success]
    refute session[:signin]

    post '/user/signin', username: 'admin', password: '1234'
    assert_equal 422, last_response.status
    assert_match /Invalid credentials/, last_response.body
    refute session[:success]
    refute session[:signin]
  end

  def test_signout_due_to_inactivity
    skip
    post '/user/signin', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status

    sleep (TIME_OUT_SECONDS + 1)

    get '/dashboard'
    assert_equal 302, last_response.status
    assert_equal 'You have been logged out due to inactivity.', session[:failure]

    assert_match /\/signin$/, last_response.location
  end

  def test_dashboard_portfolio
    get '/dashboard', {}, admin_session
    assert_equal 200, last_response.status

    current_prices = parse_api(CURRENT_PRICES_API)
    btc_price = current_prices['BTC']['USD']
    eth_price = current_prices['ETH']['USD']
    btc_counter_value = format_number((0.987 * btc_price))
    eth_counter_value = format_number((2.896 * eth_price))

    [
      /Bitcoin[\s\S]+0.987 BTC[\s\S]+#{btc_counter_value}/,
      /Ether[\s\S]+2.896 ETH[\s\S]+#{eth_counter_value}/,
      /US Dollars[\s\S]+6320 USD/,
      /Your Portfolio/,
      /<table .+>/,
    ]    
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_new_user_signin
    post '/user/signup', username: 'hello', password: '12345', agreed: 'true'
    assert_equal 302, last_response.status
    users_data = read_users_data_yml
    assert_equal true, users_data['hello'][:new_user]

    post '/user/signin', username: 'hello', password: '12345'
    assert_equal 302, last_response.status
    assert_match /Sign-up bonus.+funded.+\$\d+/, session[:success]
    users_data = read_users_data_yml
    refute users_data['hello'][:new_user]
  end
end