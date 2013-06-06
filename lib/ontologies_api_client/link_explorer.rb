require 'cgi'
require_relative 'http'

module LinkedData
  module Client
    class LinkExplorer
      HTTP = LinkedData::Client::HTTP
      
      def initialize(links)
        @links = links
      end
      
      def method_missing(meth, *args, &block)
        if @links.key?(meth.to_s)
          explore_link(meth, *args)
        elsif meth == :batch
          explore_links(*args)
        else
          super
        end
      end
      
      def respond_to?(meth)
        if @links.key?(meth.to_s) || meth == :batch
          return true
        else
          super
        end
      end
      
      def explore_link(*args)
        link = @links[args.shift.to_s]
        url = replace_template_elements(link.to_s, args)
        value_cls = LinkedData::Client::Base.class_for_type(link.media_type)
        params = {include: value_cls.attributes(*args)}
        HTTP.get(url, params)
      end
      
      def replace_template_elements(url, values = [])
        return url if values.empty?
        return url.gsub(/(\{.*?\})/) do
          CGI.escape(values.shift)
        end
      end
      
      def explore_links(*args)
        paths = args.each.map {|p| [p.to_s, p.media_type]}
        HTTP.batch_get(args)
      end
    end
  end
end