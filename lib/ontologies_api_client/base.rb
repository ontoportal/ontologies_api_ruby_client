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
      def self.attributes(full = false)
        if full && @include_attrs_full
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
        read_only = options.delete(:read_only) || false
        values = options[:values] || options
        if values.is_a?(Hash) && !values.empty?
          values = Hash[values.map { |k,v| [k.to_sym, v] }]
          instance_values_cls = Struct.new(*values.keys)
          @instance_values = instance_values_cls.new(*values.values)
        else
          @instance_values = values
        end
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
      
      ##
      # Retrieve a set of data using a link provided on an object
      # This instantiates an instance of this class and uses
      # method missing to determine which link to follow
      def explore
        LinkedData::Client::LinkExplorer.new(@links)
      end
      
      def id
        @instance_values["@id"]
      end
      
      def to_hash
        dump = marshal_dump
        dump[0].merge(dump[1])
      end
      
      def marshal_dump
        instance_values = Hash[@instance_values.members.map { |v| [ v, @instance_values[v] ] }]
        instance_variables = Hash[self.instance_variables.map { |v| [v, self.instance_variable_get("#{v}")] unless v == :@instance_values }]
        [instance_values, instance_variables]
      end
      
      def marshal_load(data)
        instance_values_hash = data.shift
        instance_values_cls = Struct.new(*instance_values_hash.keys)
        @instance_values = instance_values_cls.new(*instance_values_hash.values)
        data.shift.each do |k,v|
          self.instance_variable_set("#{k}", v) unless k.to_sym == :instance_values
        end
      end
      
    end
  end
end
