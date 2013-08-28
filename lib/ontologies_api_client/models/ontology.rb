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
        def licensed?; false; end
        def viewing_restricted?; false; end

        def flat?
          self.flat
        end
  
        def private?
          viewingRestriction && viewingRestriction.downcase.eql?("private")
        end

        def licensed?
          viewingRestriction && viewingRestriction.downcase.eql?("licensed")
        end

        def purl
          "PURL not implemented"
        end
        
        def admin?(user)
          return false if user.nil?
          return true if user.admin?
          return administeredBy.any? {|u| u == user.id}
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
