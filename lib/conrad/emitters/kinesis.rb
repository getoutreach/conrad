require 'conrad/errors'

module Conrad
  # A module containing all of conrad's built in event emitters for outputting
  # events
  module Emitters
    # Basic emitter for sending events to AWS's kinesis event stream. The emitter will
    # attempt to use values configured in the running environment according to
    # the AWS SDK documentation (such as from ~/.aws/credentials).
    class Kinesis < AmazonBase
      # @return [String] the configured kinesis stream name
      attr_accessor :stream_name

      # Sends an event up to Kinesis
      #
      # @param event [String] the event to be sent as a Kinesis message body
      def call(event)
        client.put_record(
          stream_name: stream_name,
          data: event,
          # There's a 256 character limit on the partition key, and it's hashed down into a value used to
          # pick the shard to put the data on
          partition_key: event.first(255)
        )
      end

      class << self
        def client_class
          Aws::Kinesis::Client
        end
      end
    end
  end
end
