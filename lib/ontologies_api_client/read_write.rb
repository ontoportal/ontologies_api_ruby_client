module LinkedData
  module Client
    module ReadWrite
      HTTP = LinkedData::Client::HTTP

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
