require_relative "../base"

module LinkedData
  module Client
    module Models
      class Slice < LinkedData::Client::Base
        include LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/Slice"
      end
    end
  end
end
