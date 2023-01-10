require 'addressable/template'
require_relative "../base"

module LinkedData
  module Client
    module Models
      class Mapping < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "http://data.bioontology.org/metadata/Mapping"

        def self.find(id, params = {})
          template = Addressable::Template.new("#{mappings_url_prefix}/{mapping}")
          HTTP.get(template.expand({mapping: id}), params)
        end

        def delete
          template = Addressable::Template.new("#{mappings_url_prefix}/{mapping}")
          HTTP.delete(template.expand({mapping: self.id}))
        end

        private

        ##
        # This is in a method because the settings are configured after
        # the VM initialization, so the rest_url could be null or wrong
        def self.mappings_url_prefix
          LinkedData::Client.settings.rest_url + "/mappings"
        end

        def mappings_url_prefix
          self.class.mappings_url_prefix
        end
      end
    end
  end
end
