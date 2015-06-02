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

        ##
        # We override the Collection::all call here to make the submissions retrieval more
        # efficient. Most of the time we actually only want the most recent submissions.
        # Allowing the triplestore to filter these is much faster than doing it in code.
        # Passing the `include_status` parameter as `READY` forces this behavior.
        def self.all(*args)
          params = args.shift || {}
          params[:include_status] ||= "READY"
          args.unshift(params)
          super(*args)
        end
      end
    end
  end
end
