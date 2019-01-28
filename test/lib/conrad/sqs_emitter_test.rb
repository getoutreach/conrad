require 'test_helper'
require 'aws-sdk'

class SqsEmitterTest < Minitest::Test
  class MockAwsCredentialResolver
    def initialize(resolve_as)
      @resolve_as = resolve_as
    end

    def mock_resolution_expectation
      @mock = Minitest::Mock.new
      @mock.expect(:set?, @resolve_as)
    end

    def verify_mock
      @mock.verify
    end

    def resolve
      @mock
    end
  end

  def test_initialize_when_missing_access_key_id_uses_implicit_creds
    initialization_mock_expectation do
      Conrad::Emitters::Sqs.new(
        queue_url: 'foobar.com',
        region: 'whatever',
        secret_access_key: 'fake'
      )
    end
  end

  def test_initialize_when_missing_secret_access_key_uses_implicit_creds
    initialization_mock_expectation do
      Conrad::Emitters::Sqs.new(
        queue_url: 'foobar.com',
        region: 'whatever',
        access_key_id: 'fake'
      )
    end
  end

  def test_initialize_when_missing_explicit_and_implicit_creds_raises_error
    resolver = MockAwsCredentialResolver.new(false)

    ::Aws::CredentialProviderChain.stub :new, resolver do
      resolver.mock_resolution_expectation

      assert_raises(Conrad::Emitters::Sqs::InvalidAwsCredentials) do
        Conrad::Emitters::Sqs.new(queue_url: 'foobar.com')
      end

      resolver.verify_mock
    end
  end

  def test_initialize_uses_explicit_creds_when_given
    access_args = { region: 'whatever', access_key_id: 'fake', secret_access_key: 'fake' }
    fake_client = { config: access_args }

    aws_client_mock = Minitest::Mock.new
    aws_client_mock.expect(:new, fake_client, [access_args])

    built_emitter = nil

    Aws::SQS.stub_const(:Client, aws_client_mock) do
      built_emitter = Conrad::Emitters::Sqs.new(queue_url: 'foobar.com', **access_args)
    end

    aws_client_mock.verify

    assert_equal fake_client[:config], built_emitter.client[:config]
  end

  private

  def initialization_mock_expectation(&_block)
    resolver = MockAwsCredentialResolver.new(true)
    aws_client_mock = Minitest::Mock.new

    ::Aws::CredentialProviderChain.stub :new, resolver do
      ::Aws::SQS::Client.stub :new, aws_client_mock do
        resolver.mock_resolution_expectation

        yield

        resolver.verify_mock
      end
    end
  end
end
