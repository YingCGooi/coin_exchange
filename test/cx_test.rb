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

  BTC_BEG = 0.987
  ETH_BEG = 2.896
  USD_BEG = 6320

  def setup
    Dir.chdir(ROOT)

    admin_data = { 
      'admin'=> {
          :password=>"$2a$10$XQq2o2l8zVCndc9Ol1MpI..T9ckk2quGlRRVdXFeKJ29ySnFkkH5W",
          :created=>"2017-11-03 22:08:11 -0500", 
          :new_user=> false,
          :balances=>{:btc=>BTC_BEG, :eth=>ETH_BEG, :usd=>USD_BEG}, 
          :transactions=>[]
        }
      }

    File.write(user_data_file_path, admin_data.to_yaml)
  end

  def teardown
    session.delete(:signin) if session[:signin]
    # File.delete('test/users_data.yml')
  end

  def format_number(num)
    whole, decimal = format('%.2f', num).split('.')
    comma_sliced = whole.reverse.scan(/\d{3}|\d+/).join(',').reverse
    comma_sliced + '.' + decimal
  end

  def read_users_data_yml
    YAML.load_file(user_data_file_path)
  end

  def btc_eth_prices
    current_prices = YAML.load_file('data/cache_prices.yml')
    [current_prices['BTC']['USD'], current_prices['ETH']['USD']]
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    [
      /BUY AND SELL CRYPTOCURRENCIES/i,
      /Sign In/i,
      /Sign Up/i,
      /View Charts/i
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_chart
    historical_bpi = fetch_histohour_chart_data('BTC', limit: 180, aggregate: 4)
    get '/charts'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_match /Bitcoin Price: \$/, last_response.body

    historical_bpi.each do |date, price|
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
    assert_includes session[:success], "Sign-up bonus!"
    assert session[:signin]

    user_data = YAML.load_file(user_data_file_path)
    assert_includes user_data, 'hello'

    assert_match /\/dashboard$/, last_response.location
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
    assert_match /signed in as 'admin'./i, session[:success]
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

    btc_price, eth_price = btc_eth_prices
    btc_counter_value = format_number((BTC_BEG * btc_price))
    eth_counter_value = format_number((ETH_BEG * eth_price))

    [
      /Bitcoin[\s\S]+#{btc_counter_value[0..-3]}/,
      /Ether[\s\S]+#{eth_counter_value[0..-3]}/,
      /US Dollars[\s\S]+6320/,
      /Your Portfolio/,
      /<table .+>/,
    ]    
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_dashboard_transactions
    post '/user/signup', username: 'hello', password: '12345', agreed: 'true'
    assert_equal 302, last_response.status

    get '/dashboard'
    assert_equal 200, last_response.status
    assert_match /Deposit[\s\S]+USD/i, last_response.body
    refute_match(/Buy Bitcoin/i, last_response.body)
    refute_match(/Sell Bitcoin/i, last_response.body)

    btc_price, _ = btc_eth_prices
    usd_amt = 1000
    corresp_btc_buy_amt = usd_amt/btc_price

    post '/user/buy/btc', usd_amount: usd_amt, coin_amount: corresp_btc_buy_amt
    assert_equal 302, last_response.status

    get '/dashboard'
    assert_equal 200, last_response.status
    assert_match /Buy Bitcoin[\s\S]+#{corresp_btc_buy_amt}/i, last_response.body

    btc_price, _ = btc_eth_prices
    usd_amt = 500
    corresp_btc_sell_amt = usd_amt/btc_price

    post '/user/sell/btc', usd_amount: 500, coin_amount: corresp_btc_sell_amt
    assert_equal 302, last_response.status

    get '/dashboard'
    assert_equal 200, last_response.status
    assert_match /Sell Bitcoin[\s\S]+#{corresp_btc_sell_amt}/i, last_response.body    
  end

  def test_new_user_signin
    post '/user/signup', username: 'hello', password: '12345', agreed: 'true'
    assert_equal 302, last_response.status
    users_data = read_users_data_yml
    assert_equal false, users_data['hello'][:new_user]
    assert_match /Sign-up bonus.+funded.+\$\d+/, session[:success]

    post '/user/signin', username: 'hello', password: '12345'
    assert_equal 302, last_response.status
    users_data = read_users_data_yml
    refute users_data['hello'][:new_user]
  end

  def test_buy_btc_page
    get '/buy/btc', {}, admin_session
    assert_equal 200, last_response.status
    btc_price, eth_price = btc_eth_prices
    usd_balance = read_users_data_yml['admin'][:balances][:usd]

    [
      /Bitcoin[\S\s]+@\$#{format_number(btc_price)[0..-3]}/,
      /Ether[\S\s]+@\$#{format_number(eth_price)[0..-3]}/,
      /USD Balance:.+#{format_number(usd_balance)}/,
      /<button.+type='submit'>[\S\s]+Buy Bitcoin[\S\s]+<\/button>/
    ]
    .each do |pattern|
      assert_match pattern, last_response.body
    end
  end

  def test_buy_eth_page
    get '/buy/eth', {}, admin_session
    assert_equal 200, last_response.status
    pattern = /<button.+type='submit'>[\S\s]+Buy Ether[\S\s]+<\/button>/
    assert_match pattern, last_response.body
  end

  def test_buy_btc_success
    get '/', {}, admin_session
    btc_price, _ = btc_eth_prices
    usd_amt = 1000
    corresp_btc_amt = usd_amt/btc_price

    post '/user/buy/btc', usd_amount: usd_amt, coin_amount: corresp_btc_amt

    assert_equal 302, last_response.status
    assert_includes session[:success], "You have successfully purchased #{corresp_btc_amt} BTC!"

    balances = read_users_data_yml['admin'][:balances]
    assert_equal USD_BEG - 1000, balances[:usd]
    assert_equal BTC_BEG + corresp_btc_amt, balances[:btc]
  end

  def test_buy_eth_success
    get '/', {}, admin_session
    _, eth_price = btc_eth_prices
    usd_amt = 1000
    corresp_eth_amt = usd_amt/eth_price

    post '/user/buy/eth', usd_amount: usd_amt, coin_amount: corresp_eth_amt
    assert_equal 302, last_response.status
    assert_includes session[:success], "You have successfully purchased #{corresp_eth_amt} ETH!"

    balances = read_users_data_yml['admin'][:balances]
    assert_equal USD_BEG - 1000, balances[:usd]
    assert_equal ETH_BEG + corresp_eth_amt, balances[:eth]    
  end

  def test_buy_btc_failure
    get '/', {}, admin_session
    btc_price, _ = btc_eth_prices

    post '/user/buy/btc', usd_amount: 1000, coin_amount: 2
    assert_equal 302, last_response.status
    assert_includes session[:failure], 'Price adjusted.'

    post '/user/buy/btc', usd_amount: 99999999, coin_amount: 99999999/btc_price
    assert_equal 302, last_response.status
    assert_includes session[:failure], 'Not enough funds'

    balances = read_users_data_yml['admin'][:balances]
    assert_equal USD_BEG, balances[:usd]
    assert_equal BTC_BEG, balances[:btc]
  end

  def test_buy_eth_failure
    get '/', {}, admin_session
    _, eth_price = btc_eth_prices

    post '/user/buy/eth', usd_amount: 1000, coin_amount: 2000
    assert_equal 302, last_response.status
    assert_includes session[:failure], 'Price adjusted.'

    post '/user/buy/eth', usd_amount: 99999999, coin_amount: 99999999/eth_price
    assert_equal 302, last_response.status
    assert_includes session[:failure], 'Not enough funds'

    balances = read_users_data_yml['admin'][:balances]
    assert_equal USD_BEG, balances[:usd]
    assert_equal ETH_BEG, balances[:eth] 
  end

  def test_sell_success
    get '/', {}, admin_session
    btc_price, eth_price = btc_eth_prices
    usd_amt = 500
    corresp_eth_amt = usd_amt/eth_price
    corresp_btc_amt = usd_amt/btc_price

    post '/user/sell/eth', usd_amount: usd_amt, coin_amount: corresp_eth_amt
    assert_equal 302, last_response.status
    assert_includes session[:success], "successfully sold #{corresp_eth_amt} ETH"

    get '/' # clear session messages

    post '/user/sell/btc', usd_amount: usd_amt, coin_amount: corresp_btc_amt
    assert_equal 302, last_response.status
    assert_includes session[:success], "successfully sold #{corresp_btc_amt} BTC"

    balances = read_users_data_yml['admin'][:balances]
    assert_equal USD_BEG + 1000, balances[:usd]
    assert_equal ETH_BEG - corresp_eth_amt, balances[:eth]
    assert_equal BTC_BEG - corresp_btc_amt, balances[:btc]  
  end

  def test_change_password
    get '/', {}, admin_session

    post '/user/update-password', old_password: 'secret', new_password: '1234'
    assert_equal 302, last_response.status
    assert_includes session[:success], 'Password successfully updated!'

    session.delete(:signin)

    post '/user/signin', username: 'admin', password: 'secret'
    assert_equal 422, last_response.status
    assert_match /invalid credentials/i, last_response.body

    post '/user/signin', username: 'admin', password: '1234'
    assert_equal 302, last_response.status
    assert_match /signed in as/i, session[:success]
  end

  def test_delete_account
    get '/', {}, admin_session

    post '/user/delete', password: 'secret'
    assert_equal 302, last_response.status
    assert_match /user.+admin.+deleted/i, session[:success]
    refute read_users_data_yml[:admin]

    get '/dashboard'
    assert_equal 302, last_response.status
    assert_match /please sign-in to continue/i, session[:failure]

    post '/user/signin', username: 'admin', password: 'secret'
    assert_equal 422, last_response.status
    assert_match /invalid credentials/i, last_response.body
  end
end