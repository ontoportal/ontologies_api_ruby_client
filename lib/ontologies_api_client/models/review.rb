require_relative "../base"

module LinkedData
  module Client
    module Models
      class Review < LinkedData::Client::Base
        class_for_type LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/Review"
      end
    end
  end
end
