module LinkedData::Client
  class ResourceIndex
    HTTP = LinkedData::Client::HTTP

    def self.resources
      get(:resources)
    end

    def self.counts(classes, params = {})
      classes = classes.is_a?(Array) ? classes : [classes]
      params.merge!(class_params_hash(classes))
      get(:counts, params)
    end

    def self.annotation_counts()
      get("annotation_counts")
    end

    def self.documents(resource_id, classes, params = {})
      classes = classes.is_a?(Array) ? classes : [classes]
      params.merge!(class_params_hash(classes))
      get("resources/#{resource_id}/search", params)
    end

    def self.documents_all_resources(classes, params = {})
      classes = classes.is_a?(Array) ? classes : [classes]
      params.merge!(class_params_hash(classes))
      get("resources/search", params)
    end

    def self.class_params_hash(classes, escape = false)
      ont_classes = {}
      classes.each do |c|
        ont_id = c.explore.ontology.id
        ont_id = escape ? CGI.escape(ont_id) : ont_id
        cls_id = escape ? CGI.escape(c.id) : c.id
        ont_classes["classes[#{ont_id}]"] ||= []
        ont_classes["classes[#{ont_id}]"] << cls_id
      end
      ont_classes.keys.each {|ont_id| ont_classes[ont_id] = ont_classes[ont_id].join(",")}
      ont_classes
    end

    def self.class_params(classes)
      ont_classes = class_params_hash(classes, true)
      ont_classes.keys.map {|ont_id| "#{ont_id}=#{ont_classes[ont_id]}"}.join("&")
    end

    private

    def self.get(path, params = {})
      path = path.to_s
      path = "/"+path unless path.start_with?("/")
      HTTP.get(base_path + path, params)
    end

    def self.base_path
      "/resource_index"
    end

  end
end