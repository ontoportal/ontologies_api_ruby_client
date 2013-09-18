require_relative "../base"
require_relative "../http"

module LinkedData
  module Client
    module Models
      class User < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite
        
        @media_type = "http://data.bioontology.org/metadata/User"
        @include_attrs    = "all"
        
        def self.authenticate(user, password)
          auth_params = {user: user, password: password, include: "all"}
          LinkedData::Client::HTTP.post("#{LinkedData::Client.settings.rest_url}/users/authenticate", auth_params)
        end
        
        def admin?
          respond_to?(:role) && role.include?("ADMINISTRATOR")
        end
      end
    end
  end
end
