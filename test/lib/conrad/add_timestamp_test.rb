require 'test_helper'
require 'conrad/processors/add_timestamp'

class AddTimestampTest < Minitest::Test
  def test_given_seconds_adds_timestamp_in_seconds
    processor = Conrad::Processors::AddTimestamp.new(units: :seconds)
    event = {}

    Time.stub :now, stubbed_time do
      assert processor.call(event) == { timestamp: stubbed_time.to_i }
    end
  end

  def test_given_milliseconds_adds_timestamp_in_milliseconds
    processor = Conrad::Processors::AddTimestamp.new(units: :milliseconds)
    event = {}

    Time.stub :now, stubbed_time do
      assert processor.call(event) == { timestamp: (stubbed_time.to_f * 1000).to_i }
    end
  end

  def test_given_no_units_add_timestamp_in_milliseconds
    processor = Conrad::Processors::AddTimestamp.new
    event = {}

    Time.stub :now, stubbed_time do
      assert processor.call(event) == { timestamp: (stubbed_time.to_f * 1000).to_i }
    end
  end

  def test_given_invalid_units_raises_argument_error
    assert_raises(ArgumentError) do
      Conrad::Processors::AddTimestamp.new(units: :never_a_unit)
    end
  end

  def test_allows_changing_the_timestamp_key
    processor = Conrad::Processors::AddTimestamp.new(timestamp_key: :when)
    event = {}

    Time.stub :now, stubbed_time do
      assert processor.call(event) == { when: (stubbed_time.to_f * 1000).to_i }
    end
  end

  private

  def stubbed_time
    Time.at 1_543_513_414.3506198
  end
end
