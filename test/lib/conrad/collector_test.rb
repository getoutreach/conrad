require 'test_helper'

class CollectorTest < Minitest::Test
  PASS_THROUGH = ->(event) { event }

  class ArbitraryTestingError < StandardError; end

  class MockLogger
    attr_reader :logs

    def initialize
      @logs = []
    end

    %i[debug info warn error fatal].each do |level|
      define_method(level) do |msg|
        @logs << { level => msg }
      end
    end
  end

  class ProcessorDropsEven
    def initialize
      @times = 0
    end

    def call(event)
      @times += 1

      throw :halt_conrad_processing if @times.even?

      event
    end
  end

  class EmitterDropsOdd
    attr_reader :events

    def initialize
      @times = 0
      @events = []
    end

    def call(event)
      @times += 1

      raise ArbitraryTestingError, 'Arbitrary odd number' if @times.odd?

      @events << event.clone
    end
  end

  class CollectingEmitter
    attr_reader :events

    def initialize
      @events = []
    end

    def call(data)
      @events << data.clone
      data
    end
  end

  class SleepyEmitter
    attr_reader :events

    def initialize
      @events = []
    end

    def call(event)
      sleep 0.1
      @events << event
    end
  end

  def setup
    Conrad.background_emit = false
  end

  def teardown
    Conrad::Collector.instance_variable_set(:@default_emit_as_batch, nil)
    Conrad::Collector.instance_variable_set(:@default_processors, nil)
    Conrad::Collector.instance_variable_set(:@default_emitter, nil)
    Conrad::Collector.instance_variable_set(:@default_formatter, nil)

    Thread.current[:conrad_collector] = nil
  end

  def test_uses_different_current_collector_per_thread
    runner_collector_id = Conrad::Collector.current.object_id

    another_thread = Thread.new { Conrad::Collector.current.object_id }
    other_collector_id = another_thread.join.value

    assert other_collector_id.is_a? Integer
    assert runner_collector_id != other_collector_id
  end

  def test_does_not_just_emit_events_added
    Conrad::Collector.current.emitter = ->(_event) { flunk 'Should not emit event' }

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    assert_equal [{ foo: 'bar' }.to_json, { fizz: 'bazz' }.to_json], Conrad::Collector.current.events
  end

  def test_does_not_add_events_when_halt_conrad_processing_is_thrown
    Conrad::Collector.current.processors = [ProcessorDropsEven.new]
    Conrad::Collector.current.emitter = ->(_event) { flunk 'Should not emit event' }

    Conrad::Collector.current.add_event(will_be: 'there')
    Conrad::Collector.current.add_event(is_not: 'there')
    Conrad::Collector.current.add_event(second: 'one')

    assert_equal [{ will_be: 'there' }.to_json, { second: 'one' }.to_json], Conrad::Collector.current.events
  end

  def test_emits_events_individually_by_default
    emitter = CollectingEmitter.new

    Conrad::Collector.current.emitter = emitter
    Conrad::Collector.current.formatter = PASS_THROUGH

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    Conrad::Collector.current.record_events

    assert_equal [{ foo: 'bar' }, { fizz: 'bazz' }], emitter.events
  end

  def test_allows_emitting_events_as_a_batch
    emitter = CollectingEmitter.new

    Conrad::Collector.current.emitter = emitter
    Conrad::Collector.current.formatter = PASS_THROUGH
    Conrad::Collector.current.emit_as_batch = true

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    Conrad::Collector.current.record_events

    assert_equal [[{ foo: 'bar' }, { fizz: 'bazz' }]], emitter.events
  end

  def test_adds_metadata_to_every_event_added
    emitter = CollectingEmitter.new

    Conrad::Collector.current.formatter = PASS_THROUGH
    Conrad::Collector.current.emitter = emitter
    Conrad::Collector.current.add_metadata(meta: 'totally')

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(boom: 'shaka')

    assert_equal [{ foo: 'bar', meta: 'totally' }, { boom: 'shaka', meta: 'totally' }], Conrad::Collector.current.events
  end

  def test_metadata_is_isolated_across_threads
    emitter = CollectingEmitter.new

    Conrad::Collector.default_formatter = PASS_THROUGH
    Conrad::Collector.default_emitter = emitter
    Conrad::Collector.current.add_metadata(meta: 'totally')

    other_thread = Thread.new do
      Conrad::Collector.current.add_metadata(separate_thread: true)
      Conrad::Collector.current.add_event(other_thread: 'multithread')
      Conrad::Collector.current.events
    end

    Conrad::Collector.current.add_event(first_thread: 'first')

    other_thread.join

    assert_equal [{ first_thread: 'first', meta: 'totally' }], Conrad::Collector.current.events
    assert_equal [{ separate_thread: true, other_thread: 'multithread' }], other_thread.value
  end

  def test_clears_events_and_metadata_after_sending_events
    Conrad::Collector.current.emitter = PASS_THROUGH
    Conrad::Collector.current.add_metadata(whatever: 'who cares')

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.record_events

    assert_equal [], Conrad::Collector.current.events
    assert_equal({}, Conrad::Collector.current.event_metadata)
  end

  def test_allows_configuring_formatter_at_instance_level
    some_proc = ->(event) { event.to_s }

    collector = Conrad::Collector.new(formatter: some_proc)
    assert_equal some_proc, collector.formatter

    collector = Conrad::Collector.new
    refute_equal some_proc, collector.formatter
    collector.formatter = some_proc
    assert_equal some_proc, collector.formatter
  end

  def test_allows_configuring_processors_at_instance_level
    some_proc = ->(event) { event.to_s }

    collector = Conrad::Collector.new(processors: [some_proc])
    assert_equal [some_proc], collector.processors

    collector = Conrad::Collector.new
    refute_equal [some_proc], collector.processors
    collector.processors = [some_proc]
    assert_equal [some_proc], collector.processors
  end

  def test_allows_configuring_emitter_at_instance_level
    some_proc = ->(event) { event.to_s }

    collector = Conrad::Collector.new(emitter: some_proc)
    assert_equal some_proc, collector.emitter

    # assignment
    collector = Conrad::Collector.new
    refute_equal some_proc, collector.emitter
    collector.emitter = some_proc
    assert_equal some_proc, collector.emitter
  end

  def test_validates_keys_for_events_are_strings_or_symbols
    assert_raises(Conrad::ForbiddenKey, 'Invalid number key') do
      Conrad::Collector.current.add_event(1 => 'failure')
    end

    assert_raises(Conrad::ForbiddenKey, 'Invalid array key') do
      Conrad::Collector.current.add_event([] => 'failure')
    end

    assert_raises(Conrad::ForbiddenKey, 'Invalid hash key') do
      Conrad::Collector.current.add_event({} => 'failure')
    end
  end

  def test_errors_on_recording_events_still_resets_event_data
    emitter = ->(_events) { raise ArbitraryTestingError, 'Something went wrong' }

    # Set `emit_as_batch` to true so that errors still bubble up.
    collector = Conrad::Collector.new(emitter: emitter, emit_as_batch: true)

    collector.add_metadata(foo: 'bar')
    collector.add_event(this: 'works')
    collector.record_events

    flunk 'An error should have been raised by #record events, the assert is in the rescue'
  rescue ArbitraryTestingError
    assert_equal({}, collector.event_metadata)
  end

  def test_an_error_raised_for_individual_event_emitting_does_not_prevent_future_events
    emitter = EmitterDropsOdd.new

    collector = Conrad::Collector.new(emitter: emitter, formatter: PASS_THROUGH)

    collector.add_event(one: 'one')
    collector.add_event(two: 'two')

    collector.record_events

    assert_equal [{ two: 'two' }], emitter.events
  end

  def test_errors_raised_for_individual_emitted_events_are_logged
    emitter = EmitterDropsOdd.new
    logger = MockLogger.new

    collector = Conrad::Collector.new(emitter: emitter, logger: logger)

    collector.add_event(one: 'one')
    collector.add_event(two: 'two')
    collector.record_events

    assert_equal 1, logger.logs.length

    logged_error = logger.logs.first

    assert_instance_of ArbitraryTestingError, logged_error[:error]
    assert_equal 'Arbitrary odd number', logged_error[:error].message
  end

  def test_background_emission
    Conrad.background_emit = true

    emitter = SleepyEmitter.new
    collector = Conrad::Collector.new(emitter: emitter, logger: Logger.new(STDOUT), formatter: PASS_THROUGH)

    assert_equal([], emitter.events)
    collector.add_event(background: :event)
    collector.record_events
    assert_equal([], emitter.events)

    sleep 1

    assert_equal([{ background: :event }], emitter.events)
  end

  def test_multiple_emitters
    emitter1  = CollectingEmitter.new
    collector = Conrad::Collector.new(emitter: [emitter1, emitter1], formatter: PASS_THROUGH)

    collector.add_event(one: :one)
    collector.add_event(two: :two)

    collector.record_events

    assert_equal 4, emitter1.events.length
    assert_equal [{ one: :one }, { two: :two }, { one: :one }, { two: :two }], emitter1.events
  end
end
