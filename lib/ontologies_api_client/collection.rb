require_relative 'config'
require_relative 'http'

module LinkedData
  module Client
    module Collection
      
      def self.class_for_typed(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def method_missing(meth, *class_for_typeblock)
          if meth.to_s =~ /^find_by_(.+)$/
            find_by($1, *args, &block)
          else
            super
          end
        end
      
        def top_level_links
          HTTP.get(LinkedData::Client.settings.rest_url)
        end
      
        def uri_from_context(object, media_type)
          object.links.each do |type, link|
            return link if link.media_type && link.media_type.downcase.eql?(media_type.downcase)
          end
        end
      
        def entry_point(media_type)
          HTTP.get(uri_from_context(top_level_links, media_type), include: @include_attrs)
        end
      
        def all(*args)
          entry_point(@media_type)
        end
        def where(params = {}, &block)
          if block_given?
            return all.select {|e| block.call(e)}
          else
            raise ArgumentException("Must provide a block to find ontologies")
          end
        end
      
        def find(id, params = {})
          found = where do |obj|
            obj.send("@id").eql?(id)
          end
          found.first
        end
      
        def find_by(attrs, *args)
          attributes = attrs.split("_and_")
          where do |obj|
            bools = []
            attributes.each_with_index do |attr, index|
              if obj.respond_to?(attr)
                bools << (obj.send(attr) == args[index])
              end
            end
            bools.all?
          end
        end
      end
    end
  end
end
