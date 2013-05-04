require 'cgi'
require_relative "../base"

module LinkedData
  module Client
    module Models
      class Ontology < LinkedData::Client::Base
        class_for_type LinkedData::Client::Collection
  
        @media_type = "http://data.bioontology.org/metadata/Ontology"
        @class_for_type_attrs    = "all"
  
        #TODO: Implement actual methods
        def private?; false; end
        def licensed?; false; end
        def viewing_restricted?; false; end
        def admin?(user); false; end
        def flat?; false; end
  
        def purl
          "PURL not implemented"
        end
      end
    end
  end
end
