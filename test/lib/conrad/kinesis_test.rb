require 'test_helper'
require 'aws-sdk'

class KinesisEmitterTest < Minitest::Test
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

  def test_client_calls_put_record_on_call
    emitter = Conrad::Emitters::Kinesis.new(
      stream_name: 'foobar',
      region: 'whatever',
      secret_access_key: 'fake'
    )

    data = { name: 'test_event' }

    mock = Minitest::Mock.new
    mock.expect :put_record, true, [Hash]

    emitter.stub :client, mock do
      assert emitter.call(data)
    end

    assert_mock mock
  end

  def test_initialize_when_missing_access_key_id_uses_implicit_creds
    initialization_mock_expectation do
      Conrad::Emitters::Kinesis.new(
        stream_name: 'foobar',
        region: 'whatever',
        secret_access_key: 'fake'
      )
    end
  end

  def test_initialize_when_missing_secret_access_key_uses_implicit_creds
    initialization_mock_expectation do
      Conrad::Emitters::Kinesis.new(
        stream_name: 'foobar',
        region: 'whatever',
        access_key_id: 'fake'
      )
    end
  end

  def test_initialize_when_missing_explicit_and_implicit_creds_raises_error
    resolver = MockAwsCredentialResolver.new(false)

    ::Aws::CredentialProviderChain.stub :new, resolver do
      resolver.mock_resolution_expectation

      assert_raises(Conrad::InvalidAwsCredentials) do
        Conrad::Emitters::Kinesis.new(stream_name: 'foobar')
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

    Aws::Kinesis.stub_const(:Client, aws_client_mock) do
      built_emitter = Conrad::Emitters::Kinesis.new(stream_name: 'foobar', **access_args)
    end

    aws_client_mock.verify

    assert_equal fake_client[:config], built_emitter.client[:config]
  end

  private

  def initialization_mock_expectation(&_block)
    resolver = MockAwsCredentialResolver.new(true)
    aws_client_mock = Minitest::Mock.new

    ::Aws::CredentialProviderChain.stub :new, resolver do
      ::Aws::Kinesis::Client.stub :new, aws_client_mock do
        resolver.mock_resolution_expectation

        yield

        resolver.verify_mock
      end
    end
  end
end
