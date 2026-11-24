require_relative "../base"

module LinkedData
  module Client
    module Models
      class SemanticArtefactCatalog < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite

        @media_type = "https://w3id.org/mod#SemanticArtefactCatalog"

        # The catalog is the API root resource, a singleton: no id to look up.
        # e.g. get(include: 'title,federated_portals')
        def self.get(params = {})
          HTTP.get(root_url, params)
        end

        # e.g. update(title: 'AgroPortal')
        def self.update(values)
          HTTP.patch(root_url, values)
        end

        def self.root_url
          LinkedData::Client.settings.rest_url
        end
        private_class_method :root_url
      end
    end
  end
end
