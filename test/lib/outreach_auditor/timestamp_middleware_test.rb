require 'test_helper'
require 'outreach_auditor/timestamp_middleware'

class TimestampMiddlewareTest < Minitest::Test
  def test_given_seconds_adds_timestamp_in_seconds
    middleware = OutreachAuditor::TimestampMiddleware.new(:seconds)
    event = {}

    Time.stub :now, stubbed_time do
      assert middleware.call(event) == { timestamp: stubbed_time.to_i }
    end
  end

  def test_given_milliseconds_adds_timestamp_in_milliseconds
    middleware = OutreachAuditor::TimestampMiddleware.new(:milliseconds)
    event = {}

    Time.stub :now, stubbed_time do
      assert middleware.call(event) == { timestamp: (stubbed_time.to_f * 1000).to_i }
    end
  end

  def test_given_no_units_add_timestamp_in_milliseconds
    middleware = OutreachAuditor::TimestampMiddleware.new
    event = {}

    Time.stub :now, stubbed_time do
      assert middleware.call(event) == { timestamp: (stubbed_time.to_f * 1000).to_i }
    end
  end

  def test_given_invalid_units_raises_argument_error
    assert_raises(ArgumentError) do
      OutreachAuditor::TimestampMiddleware.new(:never_a_unit)
    end
  end

  private

  def stubbed_time
    Time.at 1_543_513_414.3506198
  end
end
