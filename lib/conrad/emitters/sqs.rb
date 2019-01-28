require 'conrad/errors'

module Conrad
  # A module containing all of conrad's built in event emitters for outputting
  # events
  module Emitters
    # Basic emitter for sending events to AWS's sqs. If all access information
    # is given, the given credentials will be used. Otherwise, the emitter will
    # attempt to use values configured in the running environment according to
    # the AWS SDK documentation (such as from ~/.aws/credentials).
    class Sqs
      # Error for responding with issues around SQS credential creation
      class InvalidAwsCredentials < ::Conrad::Error
        # :nodoc:
        def to_s
          'Must provide secret_access_key, access_key_id, and region OR rely ' \
          'on configured values in the running environment.'
        end
      end

      # @return [String] the configured SQS queue URL
      attr_reader :queue_url

      # @deprecated Will be removed in 3.0.0, no migration path
      # @return [String, nil] the configured region
      attr_reader :region

      # @deprecated Will be removed in 3.0.0, no migration path
      # @return [String, nil] the configured AWS Access key ID
      attr_reader :access_key_id

      # @deprecated Will be removed in 3.0.0, no migration path
      # @return [String, nil] the configured AWS secret access key
      attr_reader :secret_access_key

      # @return [Aws::SQS::Client] the created client
      attr_reader :client

      # @param queue_url [String] the queue to send messages to
      # @param region [String] region the queue lives in
      # @param access_key_id [String] AWS Acesss Key ID
      # @param secret_access_key [String] AWS Secret Access Key
      #
      # @raise [InvalidAwsCredentials] if any of region, access_key_id, or
      #   secret_access_key are not provided AND the running environment does
      #   not have valid AWS credentials
      def initialize(queue_url:, region: nil, access_key_id: nil, secret_access_key: nil)
        @queue_url = queue_url
        @region = region
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key

        create_client(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
      end

      # Sends an event up to SQS
      def call(event)
        @client.send_message(queue_url: queue_url, message_body: event)
      end

      private

      def create_client(region:, access_key_id:, secret_access_key:)
        if secret_access_key.nil? || access_key_id.nil? || region.nil?
          validate_implicit_credentials

          @client = Aws::SQS::Client.new
        else
          @client = Aws::SQS::Client.new(
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          )
        end
      end

      def validate_implicit_credentials
        raise InvalidAwsCredentials unless Aws::CredentialProviderChain.new.resolve.set?
      end
    end
  end
end
