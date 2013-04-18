require_relative 'config'
require_relative 'http'

module LinkedData
  module Client
    class Base
      HTTP = LinkedData::Client::HTTP
      attr_writer :instance_values
      attr_accessor :context, :links
      
      # This classes' media type
      class << self
        attr_reader :media_type, :include
      end
      
      def self.all(*args)
        entry_point(@media_type)
      end
      
      def self.where(params = {}, &block)
        if block_given?
          return all.select {|e| block.call(e)}
        else
          raise ArgumentException("Must provide a block to find ontologies")
        end
      end
      
      def self.find(id, params = {})
        found = self.where do |obj|
          obj.send("@id").eql?(id) rescue binding.pry
        end
        found.first
      end
      
      def self.find_by(attrs, *args)
        attributes = attrs.split("_and_")
        self.where do |obj|
          bools = []
          attributes.each_with_index do |attr, index|
            if obj.respond_to?(attr)
              bools << (obj.send(attr) == args[index])
            end
          end
          bools.all?
        end
      end
      
      def self.object_for_type(media_type)
        classes = LinkedData::Client::Models.constants
        classes.each do |cls|
          media_type_cls = LinkedData::Client::Models.const_get(cls)
          return media_type_cls if media_type_cls.media_type.eql?(media_type)
        end
        nil
      end
      
      def self.method_missing(meth, *args, &block)
        if meth.to_s =~ /^find_by_(.+)$/
          self.find_by($1, *args, &block)
        else
          super
        end
      end
      
      def self.top_level_links
        HTTP.get(LinkedData::Client.settings.rest_url)
      end
      
      def self.entry_point(media_type)
        HTTP.get(uri_from_context(top_level_links, media_type), include: @include)
      end
      
      def self.uri_from_context(object, media_type)
        object.links.each do |type, link|
          return link if link.media_type && link.media_type.downcase.eql?(media_type.downcase)
        end
      end
      
      def initialize(values = nil)
        @instance_values = values
      end

      def method_missing(meth, *args, &block)
        if @instance_values && @instance_values.respond_to?(meth)
          @instance_values.send(meth, *args, &block)
        else
          super
        end
      end
      
      def respond_to?(meth)
        if @instance_values && @instance_values.respond_to?(meth)
          return true
        else
          super
        end
      end
      
      def explore
        LinkedData::Client::LinkExplorer.new(@links)
      end
      
      def id
        @instance_values["@id"]
      end
      
      def save
      end
      
      def update
      end
      
      def delete
      end
      
    end
  end
end

module LinkedData
  module Client
    module Models
      class Ontology < LinkedData::Client::Base
        require 'cgi'
        
        @media_type = "http://data.bioontology.org/metadata/Ontology"
        @include    = "all"
        
        #TODO: Implement actual methods
        def private?; false; end
        def licensed?; false; end
        def viewing_restricted?; false; end
        def admin?(user); false; end
        def flat?; false; end
        
        def purl
          "PURL not implemented"
        end
      end
      
      class OntologySubmission < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/OntologySubmission"
        @include    = "all"
      end

      class User < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/User"
        @include    = "all"
      end
      
      class Review < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/Review"
      end
      
      class Project < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/Project"
      end
      
      class Group < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/Group"
      end
      
      class Category < LinkedData::Client::Base
        @media_type = "http://data.bioontology.org/metadata/Category"
      end
      
      class Class < LinkedData::Client::Base
        require 'cgi'
        HTTP = LinkedData::Client::HTTP
        @media_type = "http://www.w3.org/2002/07/owl#Class"
        @include = "prefLabel,definition,synonym,properties,childrenCount,children"
        
        attr_accessor :parent
        alias :fullId :id
        
        # TODO: Implement properly
        def obsolete?; false; end
        def relation_icon; ""; end
        
        def self.find(id, ontology, params = {})
          ontology = HTTP.get(ontology, params)
          ontology.explore.class(CGI.escape(id))
        end
        
        def self.where(*args)
          raise NoMethodError, "Method not supported for LinkedData::Client::Class"
        end

        def self.all(*args)
          raise NoMethodError, "Method not supported for LinkedData::Client::Class"
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
        
        def save(*args)
          raise NoMethodError, "Method not supported for LinkedData::Client::Class"
        end
        
        def update(*args)
          raise NoMethodError, "Method not supported for LinkedData::Client::Class"
        end
        
        def delete(*args)
          raise NoMethodError, "Method not supported for LinkedData::Client::Class"
        end
      end
        
    end
  end
end

