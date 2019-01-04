module Conrad
  # A module containing all of conrad's built in event emitters for outputting events
  module Emitters
    # Basic emitter for sending events to AWS's sqs.
    class Sqs
      attr_reader :queue_url, :region, :access_key_id, :secret_access_key

      # Takes in and stores SQS region, url and creds for accessing a queue.
      def initialize(queue_url:, region:, access_key_id:, secret_access_key:)
        @queue_url = queue_url
        @region = region
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
      end

      # Sends an event up to SQS
      def call(event)
        client.send_message(queue_url: queue_url, message_body: event)
      end

      private

      def client
        @client ||= Aws::SQS::Client.new(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
      end
    end
  end
end
