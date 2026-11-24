require_relative '../test_case'
require 'pry'
require 'benchmark'
require 'webmock'
require 'request_store'

class FederationTest < LinkedData::Client::TestCase

  # Some tests federate globally through RequestStore; don't leak it into the next one
  def teardown
    RequestStore.clear!
  end

  def test_federated_ontologies_all
    ontologies = []
    time1 = Benchmark.realtime do
      ontologies = LinkedData::Client::Models::Ontology.all(display_links: false, display_context: false)
    end

    ontologies_federate_all = []
    time2 = Benchmark.realtime do
      ontologies_federate_all = LinkedData::Client::Models::Ontology.all(federate: true, display_links: false, display_context: false)
    end

    puts ""
    puts "AgroPortal ontologies: #{ontologies.length} in #{time1}s"
    puts "Federated ontologies: #{ontologies_federate_all.length} in #{time2}s"

    refute_equal ontologies.length, ontologies_federate_all.length

    ontologies_federate_all.reject{|x| x.errors}.group_by{|x| x.id.split('/')[0..-2].join('/')}.each do |portal, onts|
      puts "#{portal} ontologies: #{onts.length}"
    end

    ontologies_federate_all_cache = []
    time2 = Benchmark.realtime do
      ontologies_federate_all_cache = LinkedData::Client::Models::Ontology.all(federate: true, display_links: false, display_context: false)
    end


    puts "Federated ontologies with cache: #{ontologies_federate_all_cache.length} in #{time2}s"

    assert_equal ontologies_federate_all_cache.size, ontologies_federate_all.size

    ontologies_federate_two = []
    time2 = Benchmark.realtime do
      ontologies_federate_two = LinkedData::Client::Models::Ontology.all(federate: [:ecoportal, :biodivportal], display_links: false, display_context: false)
    end

    puts "Federated ontologies  with two portal only with cache: #{ontologies_federate_two.length} in #{time2}s"

    refute_equal ontologies_federate_two.size, ontologies_federate_all.size
  end

  def test_federated_submissions_all
    onts = []
    time1 = Benchmark.realtime do
      onts = LinkedData::Client::Models::OntologySubmission.all
    end

    onts_federate = []
    time2 = Benchmark.realtime do
      onts_federate = LinkedData::Client::Models::OntologySubmission.all(federate: true)
    end

    puts ""
    puts "AgroPortal submissions: #{onts.length} in #{time1}s"
    puts "Federated submissions: #{onts_federate.length} in #{time2}s"

    refute_equal onts.length, onts_federate.length

    onts_federate.reject{|x| x.errors}.group_by{|x| x.id.split('/')[0..-4].join('/')}.each do |portal, onts|
      puts "#{portal} submissions: #{onts.length}"
    end

    onts_federate = []
    time2 = Benchmark.realtime do
      onts_federate = LinkedData::Client::Models::OntologySubmission.all(federate: true)
    end
    puts "Federated submissions with cache: #{onts_federate.length} in #{time2}s"

  end

  def test_federation_middleware
    ontologies_federate_one = LinkedData::Client::Models::Ontology.all(federate: [:ecoportal, :biodivportal], display_links: false, display_context: false)

    RequestStore.store[:federated_portals] = [:ecoportal, :biodivportal] #saved globally

    ontologies_federate_two = LinkedData::Client::Models::Ontology.all(display_links: false, display_context: false)
    assert_equal ontologies_federate_one.size, ontologies_federate_two.size
  end


  def test_federation_error
    WebMock.enable!
    LinkedData::Client::Models::Ontology.all(invalidate_cache: true)
    WebMock.stub_request(:get, "#{LinkedData::Client.settings.rest_url.chomp('/')}/ontologies?include=all&display_links=false&display_context=false")
           .to_return(body: "Internal server error", status: 500)

    ontologies_federate_one = LinkedData::Client::Models::Ontology.all(federate: [:ecoportal, :biodivportal], display_links: false, display_context: false, invalidate_cache: true)

    assert_equal "Problem retrieving #{LinkedData::Client.settings.rest_url}/ontologies", ontologies_federate_one.first.errors

    WebMock.disable!
  end

  def test_federated_analytics
    RequestStore.store[:federated_portals] = [:ecoportal,:biodivportal]
    analytics = LinkedData::Client::Analytics.last_month
    refute_empty analytics.onts
  end


  def test_federation_ssl_error
    WebMock.enable!
    WebMock.stub_request(:get, "#{LinkedData::Client.settings.rest_url.chomp('/')}")
           .to_raise(Faraday::SSLError)
    ontologies_federate_one = LinkedData::Client::Models::Ontology.all(display_links: false, display_context: false, invalidate_cache: true)

    refute_nil ontologies_federate_one.first.errors
    WebMock.disable!
  end

  def test_federated_search
    query = 'test'

    time1 = Benchmark.realtime do
      @search_results = LinkedData::Client::Models::Class.search(query).collection
    end

    time2 = Benchmark.realtime do
      @federated_search_results = LinkedData::Client::Models::Class.search(query, {federate: 'true'}).collection
    end

    puts "Search results: #{@search_results.length} in #{time1}s"
    puts "Federated search results: #{@federated_search_results.length} in #{time2}s"

    refute_equal @search_results.length, @federated_search_results.length
  end
end
