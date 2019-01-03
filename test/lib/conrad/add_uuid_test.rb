require 'test_helper'
require 'conrad/processors/add_uuid'

class AddUUIDTest < Minitest::Test
  def test_adds_uuid_to_hash
    event = { a: 'apple' }
    processor = Conrad::Processors::AddUUID.new

    SecureRandom.stub :uuid, 'abcd' do
      assert processor.call(event) == { a: 'apple', event_uuid: 'abcd' }
    end
  end

  def test_allows_changing_the_event_id_key
    event = { a: 'apple' }
    processor = Conrad::Processors::AddUUID.new(:id)

    SecureRandom.stub :uuid, 'abcd' do
      assert processor.call(event) == { a: 'apple', id: 'abcd' }
    end
  end
end
