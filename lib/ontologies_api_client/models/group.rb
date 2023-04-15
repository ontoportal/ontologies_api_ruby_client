require_relative "../base"

module LinkedData
  module Client
    module Models
      class Group < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://data.bioontology.org/metadata/Group"
      end
    end
  end
end
