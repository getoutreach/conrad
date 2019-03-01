require 'conrad/errors'

module Conrad
  # A module containing all of conrad's built in event emitters for outputting
  # events
  module Emitters
    # Basic emitter for sending events to AWS's kinesis event stream. The emitter will
    # attempt to use values configured in the running environment according to
    # the AWS SDK documentation (such as from ~/.aws/credentials).
    class Kinesis
      # Error for responding with issues around kinesis credential creation
      class InvalidAwsCredentials < ::Conrad::Error
        # :nodoc:
        def to_s
          'Must provide secret_access_key and access_key_id OR rely ' \
          'on configured values in the running environment.'
        end
      end

      # @return [String] the configured kinesis stream name
      attr_reader :stream_name

      # @return [String, nil] the configured aws region
      attr_reader :region

      # @return [Aws::Kinesis::Client] the created client
      attr_reader :client

      # @param stream_name [String] the name of the kinesis stream to send messages to
      # @param region [String] region the stream lives in
      # @param access_key_id [String] AWS Acesss Key ID
      # @param secret_access_key [String] AWS Secret Access Key
      #
      # @raise [InvalidAwsCredentials] if access_key_id or secret_access_key are
      #   not provided AND the running environment does not have valid AWS
      #   credentials
      # @raise [Aws::Errors::MissingRegionError] if region is not provided and
      #   also not set via an allowed AWS environment variable
      def initialize(stream_name:, region: nil, access_key_id: nil, secret_access_key: nil)
        @stream_name = stream_name

        create_client(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
      end

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

      private

      def create_client(region: nil, access_key_id: nil, secret_access_key: nil)
        if secret_access_key.nil? || access_key_id.nil?
          validate_implicit_credentials

          @client = Aws::Kinesis::Client.new({ region: region }.compact)
        else
          @client = Aws::Kinesis::Client.new({
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }.compact)
        end
      end

      def validate_implicit_credentials
        raise InvalidAwsCredentials unless Aws::CredentialProviderChain.new.resolve.set?
      end
    end
  end
end
