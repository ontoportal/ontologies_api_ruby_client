require 'cgi'
require_relative "../base"

module LinkedData
  module Client
    module Models
      class Ontology < LinkedData::Client::Base
        include LinkedData::Client::Collection
        include LinkedData::Client::ReadWrite
  
        @media_type = "http://data.bioontology.org/metadata/Ontology"
        @include_attrs    = "all"
  
        #TODO: Implement actual methods
        def private?; false; end
        def licensed?; false; end
        def viewing_restricted?; false; end
        def admin?(user); false; end
        def flat?; false; end
  
        def purl
          "PURL not implemented"
        end
        
        # For use with select lists, always includes the admin by default
        def acl_select
          select_opts = []
          return select_opts if self.acl.nil? or self.acl.empty?

          if self.acl.nil? || self.acl.empty?
            self.administeredBy.each do |userId|
              select_opts << [User.get(userId).username, userId]
            end
          else
            self.acl.each do |userId|
              select_opts << [User.get(userId).username, userId]
            end
          end

          (select_opts + self.administeredBy).uniq
        end
        
      end
    end
  end
end
