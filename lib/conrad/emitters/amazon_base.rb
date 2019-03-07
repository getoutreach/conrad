require 'active_model'

module Conrad
  module Emitters
    # Base class for AWS-based emitters
    class AmazonBase
      include ::ActiveModel::Model

      # @return [String, nil] the configured region
      attr_accessor :region

      # @deprecated Will be removed in 3.0.0, no migration path
      # @return [String, nil] the configured AWS Access key ID
      attr_accessor :access_key_id

      # @deprecated Will be removed in 3.0.0, no migration path
      # @return [String, nil] the configured AWS secret access key
      attr_accessor :secret_access_key

      # @return [Aws::SQS::Client] the created client
      attr_accessor :client

      # @param queue_url [String] the queue to send messages to
      # @param region [String] region the queue lives in
      # @param access_key_id [String] AWS Acesss Key ID
      # @param secret_access_key [String] AWS Secret Access Key
      #
      # @raise [InvalidAwsCredentials] if access_key_id or secret_access_key are
      #   not provided AND the running environment does not have valid AWS
      #   credentials
      # @raise [Aws::Errors::MissingRegionError] if region is not provided and
      #   also not set via an allowed AWS environment variable
      def initialize(args = {})
        super
        create_client(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
      end

      private

      def create_client(region:, access_key_id:, secret_access_key:)
        if secret_access_key.nil? || access_key_id.nil?
          validate_implicit_credentials

          @client = self.class.client_class.new({ region: region }.compact)
        else
          @client = self.class.client_class.new({
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          }.compact)
        end
      end

      def validate_implicit_credentials
        raise Conrad::InvalidAwsCredentials unless Aws::CredentialProviderChain.new.resolve&.set?
      end
    end
  end
end
