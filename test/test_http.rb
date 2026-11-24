require_relative 'test_case'
require 'rack/multipart'
require 'stringio'

class HTTPTest < LinkedData::Client::TestCase
  def test_multipart_upload_can_be_parsed_by_rack
    metadata = { 'hasOntologyLanguage' => 'OWL', 'description' => 'Ontology café' }
    contents = "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"/>\n"
    upload = Faraday::UploadIO.new(StringIO.new(contents), 'application/rdf+xml', 'ontology.owl')
    request = Faraday.new.build_request(:post)

    LinkedData::Client::HTTP.custom_req(metadata, upload, :file, request)

    body = request.body.read
    assert_equal body.bytesize.to_s, request.headers['Content-Length']
    env = {
      'CONTENT_TYPE' => request.headers['Content-Type'],
      'CONTENT_LENGTH' => request.headers['Content-Length'],
      'rack.input' => StringIO.new(body)
    }

    # Rack 3.2.9 rejects an unquoted type=application/json parameter
    parsed = Rack::Multipart.parse_multipart(env)

    assert_equal %w[file json], parsed.keys.sort
    assert_equal metadata, MultiJson.load(parsed.fetch('json'))
    file = parsed.fetch('file')
    assert_equal 'ontology.owl', file.fetch(:filename)
    assert_equal 'application/rdf+xml', file.fetch(:type)
    assert_equal contents, file.fetch(:tempfile).read
  ensure
    request&.body&.close
    Array(env && env['rack.tempfiles']).each(&:close!)
  end

  def test_request_without_file_sends_json
    metadata = { 'hasOntologyLanguage' => 'OWL', 'description' => 'Ontology café' }
    request = Faraday.new.build_request(:post)

    LinkedData::Client::HTTP.custom_req(metadata, nil, nil, request)

    assert_equal 'application/json', request.headers['Content-Type']
    assert_equal metadata, MultiJson.load(request.body)
  end

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
