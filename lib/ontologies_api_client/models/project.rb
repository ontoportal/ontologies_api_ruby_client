require_relative "../base"

module LinkedData
  module Client
    module Models
      class Project < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://data.bioontology.org/metadata/Project"
      end
    end
  end
end
