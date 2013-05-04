require_relative "../base"

module LinkedData
  module Client
    module Models
      class Group < LinkedData::Client::Base
        include LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/Group"
      end
    end
  end
end
