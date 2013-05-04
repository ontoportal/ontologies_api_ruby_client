require_relative "../base"

module LinkedData
  module Client
    module Models
      class Class < LinkedData::Client::Base
        require 'cgi'
        HTTP = LinkedData::Client::HTTP
        @media_type = "http://www.w3.org/2002/07/owl#Class"
        @class_for_type_attrs = "prefLabel,definition,synonym,properties,childrenCount,children"
  
        attr_accessor :parent
        alias :fullId :id
  
        # TODO: Implement properly
        def obsolete?; false; end
        def relation_icon; ""; end
  
        def self.find(id, ontology, params = {})
          ontology = HTTP.get(ontology, params)
          ontology.explore.class(CGI.escape(id))
        end
  
        def expanded?
          !children.nil? && children.length > 0
        end
  
        def children
          # if @children.nil?
          #   return self.explore.children.collection
          # end
          @children
        end
  
        def children=(children)
          @children = children
        end
  
      end
    end
  end
end