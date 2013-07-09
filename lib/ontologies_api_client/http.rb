require 'oj'
require 'multi_json'
require 'digest'

module LinkedData
  module Client
    module HTTP
      class Link < String; attr_accessor :media_type; end
      
      OBJ_CACHE = {}
      GET_CACHE = {}
      ENABLE_CACHE = true
      
      def self.conn
        LinkedData::Client.settings.conn
      end
      
      def self.get(path, params = {})
        params = params.delete_if {|k,v| v == nil || v.to_s.empty?}
        
        begin
          if ENABLE_CACHE && GET_CACHE[[path, params].hash]
            obj = GET_CACHE[[path, params].hash]
          else
            puts "Getting: #{path} with #{params}"
            response = conn.get path, params
            body = response.body
            obj = rucursive_struct(load_json(body))
            GET_CACHE[[path, params].hash] = obj if response.status < 400 && ENABLE_CACHE
          end
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
        conn.post do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = obj.to_json
        end
      end
      
      def self.put(path, obj)
        conn.put do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = obj.to_json
        end
      end
      
      def self.patch(path, params)
        conn.put do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.body = params.to_json
        end
      end
      
      def self.delete(id)
        puts "Deleting #{id}"
        conn.delete id
      end
      
      private
      
      def self.rucursive_struct(json_obj)
        # TODO: Convert dates to date objects
        if json_obj.is_a?(Hash)
          value_cls = LinkedData::Client::Base.class_for_type(json_obj["@type"])
          links = prep_links(json_obj) # strip links
          context = json_obj.delete("@context") # strip context
          
          # Create a struct with the left-over attributes to store data
          attributes = json_obj.keys.map {|k| k.to_sym}
          attributes_always_present = value_cls.attrs_always_present || [] rescue []
          attributes = (attributes + attributes_always_present).uniq
          
          # Either get the struct class from cache or create a new one (and store it in the cache)
          obj_cls = cls_for_keys(attributes)

          # Create objects for each key/value pair, recursively
          values = []
          json_obj.each do |key, value|
            values << rucursive_struct(value)
          end
          
          # New instance using struct
          new_values = obj_cls.new(*values)
          
          # Either create a known object type (see value_cls assignment above) or use struct
          obj = value_cls ? value_cls.new(values: new_values) : new_values
          
          # Assign links/context
          obj.links = links if links
          obj.context = context if context
        elsif json_obj.is_a?(Array)
          obj = []
          json_obj.each do |value|
            obj << rucursive_struct(value)
          end
        else
          obj = value_cls ? value_cls.new(values: json_obj) : json_obj
        end
        obj
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
