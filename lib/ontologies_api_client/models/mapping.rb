require "cgi"
require_relative "../base"

module LinkedData
  module Client
    module Models
      class Mapping < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://data.bioontology.org/metadata/Mapping"

        def self.find(id, params = {})
          HTTP.get(mappings_url_prefix + CGI.escape(id), params)
        end

        def delete
          HTTP.delete(mappings_url_prefix + CGI.escape(self.id))
        end

        private

        ##
        # This is in a method because the settings are configured after
        # the VM initialization, so the rest_url could be null or wrong
        def self.mappings_url_prefix
          LinkedData::Client.settings.rest_url + "/mappings/"
        end

        def mappings_url_prefix
          self.class.mappings_url_prefix
        end
      end
    end
  end
end
