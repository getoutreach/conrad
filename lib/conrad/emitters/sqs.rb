require 'conrad/errors'

module Conrad
  # A module containing all of conrad's built in event emitters for outputting
  # events
  module Emitters
    # Basic emitter for sending events to AWS's sqs. If all access information
    # is given, the given credentials will be used. Otherwise, the emitter will
    # attempt to use values configured in the running environment according to
    # the AWS SDK documentation (such as from ~/.aws/credentials).
    class Sqs < AmazonBase
      # @return [String] the configured SQS queue URL
      attr_accessor :queue_url

      # Sends an event up to SQS
      #
      # @param event [String] the event to be sent as an SQS message body
      def call(event)
        client.send_message(queue_url: queue_url, message_body: event)
      end

      class << self
        def client_class
          Aws::SQS::Client
        end
      end
    end
  end
end
