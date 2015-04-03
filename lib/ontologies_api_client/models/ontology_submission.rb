require_relative "../base"

module LinkedData
  module Client
    module Models
      class OntologySubmission < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite
        @media_type = "http://data.bioontology.org/metadata/OntologySubmission"
        @include_attrs = "all"

        PRETTY_FORMATS = {
          "UMLS" => "RDF/TTL"
        }
        def pretty_format
          PRETTY_FORMATS[self.hasOntologyLanguage] || self.hasOntologyLanguage
        end
      end
    end
  end
end
