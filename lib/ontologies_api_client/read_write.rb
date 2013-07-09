HTTP = LinkedData::Client::HTTP

module LinkedData
  module Client
    module ReadWrite
      def save
        # Create via post
        HTTP.post(self.class.collection_path, self.to_hash)
      end
      
      def delete
        HTTP.delete(self.id)
      end
    end
  end
end
