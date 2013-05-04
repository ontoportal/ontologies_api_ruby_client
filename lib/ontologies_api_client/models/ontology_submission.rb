require_relative "../base"

module LinkedData
  module Client
    module Models
      class OntologySubmission < LinkedData::Client::Base
        class_for_type LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/OntologySubmission"
        @class_for_type_attrs    = "all"
      end
    end
  end
end