require 'oj'
require 'multi_json'
require 'digest'

module LinkedData
  module Client
    module HTTP
      class Link < String; attr_accessor :media_type; end

      OBJ_CACHE = {}
      
      def self.conn
        unless LinkedData::Client.connection_configured?
          if Kernel.const_defined?("Rails")
            rails = Kernel.const_get("Rails")
            store = rails.cache if rails.cache
          end
          LinkedData::Client.config_connection(cache_store: store)
        end
        LinkedData::Client.settings.conn
      end
      
      def self.get(path, params = {})
        params = params.delete_if {|k,v| v == nil || v.to_s.empty?}
        
        begin
          puts "Getting: #{path} with #{params}" if $DEBUG
          begin
            response = conn.get do |req|
              req.url path
              req.params = params
              req.options[:timeout] = 60
            end
          rescue Exception => e
            params = Faraday::Utils.build_query(params)
            path << "?" unless params.empty?
            raise e, "Problem retrieving:\n#{path}#{params}\n\nError: #{e.message}\n#{e.backtrace.join("\n\t")}"
          end
          response = response.dup if response && response.frozen?
          return response unless response.kind_of?(Faraday::Response)
          
          body = response.body
          raise Exception, "Problem retrieving:\n#{path}\n#{body}" if response.status >= 500
          obj = recursive_struct(load_json(body))
        rescue Exception => e
          puts "Problem getting #{path}" if $DEBUG
          raise e
        end
        obj
      end
      
      def self.get_batch(paths, params = {})
        responses = []
        if conn.in_parallel?
          conn.in_parallel do
            paths.each {|p| responses << conn.get(p, params) }
          end
        else
          responses = threaded_request(paths, params)
        end
        return responses
      end
      
      def self.post(path, obj)
        obj = params_file_handler(obj)
        response = conn.post path, obj
        raise Exception, response.body if response.status >= 500
        recursive_struct(load_json(response.body))
      end
      
      def self.put(path, obj)
        obj = params_file_handler(obj)
        response = conn.put path, obj
        recursive_struct(load_json(response.body))
        raise Exception, response.body if response.status >= 500
        recursive_struct(load_json(response.body))
      end
      
      def self.patch(path, params)
        params = params_file_handler(params)
        response = conn.patch path, params
        raise Exception, response.body if response.status >= 500
      end
      
      def self.delete(id)
        puts "Deleting #{id}" if $DEBUG
        response = conn.delete id
        raise Exception, response.body if response.status >= 500
      end
      
      def self.object_from_json(json)
        recursive_struct(load_json(json))
      end
      
      private
      
      def self.params_file_handler(params)
        return if params.nil?
        params.dup.each do |attribute, value|
          next unless value.is_a?(File) || value.is_a?(Tempfile)
          params[attribute] = Faraday::UploadIO.new(value.path, "text/plain")
        end
        params
      end
      
      def self.threaded_request(paths, params)
        threads = []
        responses = []
        paths.each do |path|
          threads << Thread.new do
            responses << get(path, params)
          end
        end
        threads.join
        responses
      end
      
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
        begin
          MultiJson.load(json)
        rescue Exception => e
          raise e, "Problem loading json\n#{json}"
        end
      end
      
      def self.dump_json(json)
        MultiJson.dump(json)
      end
    end
  end
end
