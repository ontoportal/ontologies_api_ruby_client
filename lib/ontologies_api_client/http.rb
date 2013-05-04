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
        
        if ENABLE_CACHE && GET_CACHE[[path, params].hash]
          obj = GET_CACHE[[path, params].hash]
        else
          response = conn.get path, params
          body = response.body
          obj = rucursive_struct(load_json(body))
          GET_CACHE[[path, params].hash] = obj if response.status < 400 && ENABLE_CACHE
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
      
      def self.post
      end
      
      def self.put
      end
      
      def self.patch
      end
      
      def self.delete
      end
      
      private
      
      def self.rucursive_struct(json_obj)
        # TODO: Convert dates to date objects
        if json_obj.is_a?(Hash)
          value_cls = LinkedData::Client::Base.class_for_type(json_obj["@type"])
          links = prep_links(json_obj)
          context = json_obj.delete("@context")
          obj_cls = cls_for_keys(json_obj.keys.map {|k| k.to_sym})
          values = []
          json_obj.each do |key, value|
            values << rucursive_struct(value)
          end
          new_values = obj_cls.new(*values)
          obj = value_cls ? value_cls.new(new_values) : new_values
          obj.links = links if links
          obj.context = context if context
        elsif json_obj.is_a?(Array)
          obj = []
          json_obj.each do |value|
            obj << rucursive_struct(value)
          end
        else
          obj = value_cls ? value_cls.new(json_obj) : json_obj
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
