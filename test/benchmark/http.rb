require 'benchmark'

require_relative '../../lib/ontologies_api_client'
LinkedData::Client.config

module LinkedData
  module Client
    class Benchmark

      def test_all_ontologies
        10.times {LinkedData::Client::Models::Ontology.all}
      end

      def test_explore_ontologies
        onts = LinkedData::Client::Models::Ontology.all
        onts.each do |ont|
          ont.explore.projects
          ont.explore.groups
          ont.explore.categories
          ont.explore.reviews
        end
      end

      def test_batch_explore_ontologies
        # onts = LinkedData::Client::Models::Ontology.all
        # onts.each do |ont|
        #   projects, groups, categories = LinkedData::Client::HTTP.get_batch([ont.links["projects"], ont.links["groups"], ont.links["categories"]])
        # end
      end

    end
  end
end

benchmark = LinkedData::Client::Benchmark.new
benchmark.public_methods(false).each do |method|
  time = ::Benchmark.realtime do
    benchmark.send(method)
  end
  puts "#{method}: #{time*1000}ms"
end