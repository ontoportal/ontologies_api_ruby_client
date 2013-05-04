require_relative "../base"

module LinkedData
  module Client
    module Models
      class User < LinkedData::Client::Base
        class_for_type LinkedData::Client::Collection
        @media_type = "http://data.bioontology.org/metadata/User"
        @class_for_type_attrs    = "all"
      end
    end
  end
end
