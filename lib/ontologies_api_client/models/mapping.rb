require_relative "../base"

module LinkedData
  module Client
    module Models
      class Mapping < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite
        
        @media_type = "http://data.bioontology.org/metadata/Mapping"
      end
    end
  end
end
