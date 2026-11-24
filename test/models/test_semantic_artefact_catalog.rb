require_relative '../test_case'
require 'webmock'
require 'tempfile'

# HTTP.patch checks for uploaded files with Rails classes, Rails isn't loaded here
module ActionDispatch
  module Http
    class UploadedFile; end
  end
end

class SemanticArtefactCatalogTest < LinkedData::Client::TestCase
  include WebMock::API

  Catalog = LinkedData::Client::Models::SemanticArtefactCatalog
  TITLE = 'AgroPortal'

  def setup
    WebMock.enable!
    @root = LinkedData::Client.settings.rest_url
  end

  def teardown
    WebMock.reset!
    WebMock.disable!
  end

  def test_get
    body = { title: TITLE, '@id': @root, '@type': Catalog.media_type }.to_json
    stub_request(:get, @root)
      .with(query: hash_including(include: 'title'))
      .to_return(body: body, headers: { 'Content-Type' => 'application/json' })

    catalog = Catalog.get(include: 'title')

    assert_instance_of Catalog, catalog
    assert_equal TITLE, catalog.title
  end

  def test_update
    stub_request(:patch, @root).with(body: { title: TITLE }.to_json).to_return(status: 204)

    response = Catalog.update(title: TITLE)

    assert_equal 204, response.status
  end
end
