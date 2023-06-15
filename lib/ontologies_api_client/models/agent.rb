require_relative "../base"

module LinkedData
  module Client
    module Models
      class Agent < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://xmlns.com/foaf/0.1/Agent"
      end
    end
  end
end
