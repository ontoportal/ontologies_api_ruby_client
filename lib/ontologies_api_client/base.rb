module LinkedData
  module Client
    class Base
      HTTP = LinkedData::Client::HTTP
      attr_writer :instance_values
      attr_accessor :context, :links
      
      class << self
        attr_accessor :media_type, :include_attrs, :include_attrs_full, :attrs_always_present
      end
      
      ##
      # Passing full: true to explore methods will give you more attributes
      def self.attributes(*args)
        options = args.pop || {}
        if options[:full] && @include_attrs_full
          @include_attrs_full
        else
          @include_attrs
        end
      end

      def self.class_for_type(media_type)
        classes = LinkedData::Client::Models.constants
        classes.each do |cls|
          media_type_cls = LinkedData::Client::Models.const_get(cls)
          return media_type_cls if media_type_cls.media_type.eql?(media_type)
        end
        nil
      end

      def initialize(options = {})
        values = options[:values]
        read_only = options[:read_only] || false
        @instance_values = values
        if read_only && self.class.attrs_always_present
          self.class.attrs_always_present.each do |attr|
            define_singleton_method(attr, lambda {instance_variable_get("@#{attr}")})
            define_singleton_method("#{attr}=", lambda {|val| instance_variable_set("@#{attr}", val)})
          end
        end
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
