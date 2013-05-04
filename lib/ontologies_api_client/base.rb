module LinkedData
  module Client
    class Base
      HTTP = LinkedData::Client::HTTP
      attr_writer :instance_values
      attr_accessor :context, :links
      
      class << self
        attr_accessor :media_type, :class_for_type_attrs
      end
      
      def self.class_for_type(media_type)
        classes = LinkedData::Client::Models.constants
        classes.each do |cls|
          media_type_cls = LinkedData::Client::Models.const_get(cls)
          return media_type_cls if media_type_cls.media_type.eql?(media_type)
        end
        nil
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
      
    end
  end
end
