require_relative 'test_case'

class HTTPTest < LinkedData::Client::TestCase
  def test_get_sends_custom_headers
    # Capture what reaches the wire instead of hitting a live API
    sent_headers = nil
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/ontologies') do |env|
      sent_headers = env.request_headers
      [200, {}, 'ok']
    end
    connection = Faraday.new { |f| f.adapter :test, stubs }

    LinkedData::Client::HTTP.get('/ontologies', {}, connection: connection, headers: { 'X-Custom' => 'yes' }, raw: true)

    assert_equal 'yes', sent_headers['X-Custom']
  end
end
