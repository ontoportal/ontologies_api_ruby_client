require 'oj'
require 'multi_json'
require 'digest'

module LinkedData
  module Client
    module HTTP
      class Link < String; attr_accessor :media_type; end

      OBJ_CACHE = {}
      
      def self.conn
        LinkedData::Client.settings.conn
      end
      
      def self.get(path, params = {})
        params = params.delete_if {|k,v| v == nil || v.to_s.empty?}
        
        begin
          puts "Getting: #{path} with #{params}"
          response = conn.get path, params
          response = response.dup if response && response.frozen?
          return response unless response.kind_of?(Faraday::Response)
          
          body = response.body
          raise Exception, body if response.status >= 500
          obj = recursive_struct(load_json(body))
        rescue Exception => e
          puts "Problem getting #{path}"
          raise e
        end
        obj
      end
      
      def self.get_batch(paths)
        responses = []
        conn.in_parallel do
          paths.each {|p| responses << conn.get(p[0], p[1]) }
        end
        return *responses
      end
      
      def self.post(path, obj)
        response = conn.post do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump(obj)
        end
        raise Exception, response.body if response.status >= 500
        recursive_struct(load_json(response.body))
      end
      
      def self.put(path, obj)
        response = conn.put do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump(obj)
        end
        recursive_struct(load_json(response.body))
      end
      
      def self.patch(path, params)
        conn.patch do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = MultiJson.dump(params)
        end
      end
      
      def self.delete(id)
        puts "Deleting #{id}"
        conn.delete id
      end
      
      def self.object_from_json(json)
        recursive_struct(load_json(json))
      end
      
      private
      
      def self.recursive_struct(json_obj)
        # TODO: Convert dates to date objects
        if json_obj.is_a?(Hash)
          return if json_obj.empty?

          value_cls = LinkedData::Client::Base.class_for_type(json_obj["@type"])
          links = prep_links(json_obj) # strip links
          context = json_obj.delete("@context") # strip context
          
          # Create a struct with the left-over attributes to store data
          attributes = json_obj.keys.map {|k| k.to_sym}
          attributes_always_present = value_cls.attrs_always_present || [] rescue []
          attributes = (attributes + attributes_always_present).uniq
          
          # Add attributes to instance
          if value_cls
            instance = value_cls.new
            attributes.each do |attr|
              attr = attr[1..-1] if attr[0].eql?("@")
              instance.class.class_eval do
                define_method attr.to_sym do
                  instance_variable_get("@#{attr}")
                end
                define_method "#{attr}=" do |val|
                  instance_variable_set("@#{attr}", val)
                end
              end
            end
            
            # Create objects for each key/value pair, recursively
            json_obj.each do |attr, value|
              attr = attr[1..-1] if attr[0].eql?("@")
              instance.instance_variable_set("@#{attr}", recursive_struct(value))
            end
          else
            # Either get the struct class from cache or create a new one (and store it in the cache)
            obj_cls = cls_for_keys(attributes)
            
            # Create objects for each key/value pair, recursively
            values = []
            json_obj.each do |key, value|
              values << recursive_struct(value)
            end
            
            # New instance using struct
            instance = obj_cls.new(*values)
          end
          
          # Assign links/context
          instance.links = links if links
          instance.context = context if context
        elsif json_obj.is_a?(Array)
          instance = []
          json_obj.each do |value|
            instance << recursive_struct(value)
          end
        else
          instance = value_cls ? value_cls.new(values: json_obj) : json_obj
        end
        instance
      end
      
      def self.prep_links(obj)
        links = obj.delete(LinkedData::Client.settings.links_attr)
        return if links.nil?
        
        context = links.delete("@context")
        return if context.nil?
        links.keys.each do |link_type|
          link = Link.new(links[link_type])
          link.media_type = context[link_type]
          links[link_type] = link
        end
        links
      end
        
      def self.cls_for_keys(keys)
        keys = keys + [:links, :context]
        OBJ_CACHE[keys.hash] ||= Struct.new(*keys)
      end
      
      def self.load_json(json)
        MultiJson.load(json)
      end
      
      def self.dump_json(json)
        MultiJson.dump(json)
      end
    end
  end
end
