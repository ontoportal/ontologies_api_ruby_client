require_relative "../base"

module LinkedData
  module Client
    module Models
      class Instance < LinkedData::Client::Base
        include LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/Instance"
      end
    end
  end
end
