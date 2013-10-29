require_relative "../base"

module LinkedData
  module Client
    module Models
      class Note < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite
        @media_type = "http://data.bioontology.org/metadata/Note"

        def deletable?(user)
          false
        end

        def uuid
          self.id.split("/").last
        end
      end
    end
  end
end
