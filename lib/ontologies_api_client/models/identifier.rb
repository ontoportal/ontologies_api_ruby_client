require_relative "../base"

module LinkedData
  module Client
    module Models
      class Identifier < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://www.w3.org/ns/adms#Identifier"
      end
    end
  end
end
