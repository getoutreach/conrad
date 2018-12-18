require 'test_helper'
require 'conrad/uuid_middleware'

class UUIDMiddlewareTest < Minitest::Test
  def test_adds_uuid_to_hash
    event = { a: 'apple' }
    middleware = Conrad::UUIDMiddleware.new

    SecureRandom.stub :uuid, 'abcd' do
      assert middleware.call(event) == { a: 'apple', event_uuid: 'abcd' }
    end
  end

  def test_allows_changing_the_event_id_key
    event = { a: 'apple' }
    middleware = Conrad::UUIDMiddleware.new(:id)

    SecureRandom.stub :uuid, 'abcd' do
      assert middleware.call(event) == { a: 'apple', id: 'abcd' }
    end
  end
end
