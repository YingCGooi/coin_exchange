ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

require_relative '../cx.rb'

Minitest::Reporters.use!

class CXTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
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
end