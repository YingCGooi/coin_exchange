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
end