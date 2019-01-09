require 'test_helper'

class CollectorTest < Minitest::Test
  PASS_THROUGH = ->(event) { event }

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

  def teardown
    Conrad::Collector.instance_variable_set(:@emit_as_batch, nil)
    Conrad::Collector.instance_variable_set(:@processor_stack, nil)
    Conrad::Collector.instance_variable_set(:@processors, nil)
    Conrad::Collector.instance_variable_set(:@emitter, nil)
    Conrad::Collector.instance_variable_set(:@formatter, nil)

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
    Conrad::Collector.emitter = ->(_event) { raise 'Should not emit event' }

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    assert_equal [{ foo: 'bar' }.to_json, { fizz: 'bazz' }.to_json], Conrad::Collector.current.events
  end

  def test_does_not_add_events_when_halt_conrad_processing_is_thrown
    Conrad::Collector.processors = [ProcessorDropsEven.new]
    Conrad::Collector.emitter = ->(_event) { raise 'Should not emit event' }

    Conrad::Collector.current.add_event(will_be: 'there')
    Conrad::Collector.current.add_event(is_not: 'there')
    Conrad::Collector.current.add_event(second: 'one')

    assert_equal [{ will_be: 'there' }.to_json, { second: 'one' }.to_json], Conrad::Collector.current.events
  end

  def test_emits_events_individually_by_default
    emitter = CollectingEmitter.new

    Conrad::Collector.emitter = emitter
    Conrad::Collector.formatter = PASS_THROUGH

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    Conrad::Collector.current.record_events

    assert_equal [{ foo: 'bar' }, { fizz: 'bazz' }], emitter.events
  end

  def test_allows_emitting_events_as_a_batch
    emitter = CollectingEmitter.new

    Conrad::Collector.emitter = emitter
    Conrad::Collector.formatter = PASS_THROUGH
    Conrad::Collector.emit_as_batch = true

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(fizz: 'bazz')

    Conrad::Collector.current.record_events

    assert_equal [[{ foo: 'bar' }, { fizz: 'bazz' }]], emitter.events
  end

  def test_adds_metadata_to_every_event_added
    emitter = CollectingEmitter.new

    Conrad::Collector.formatter = PASS_THROUGH
    Conrad::Collector.emitter = emitter
    Conrad::Collector.current.event_metadata = { meta: 'totally' }

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.add_event(boom: 'shaka')

    assert_equal [{ foo: 'bar', meta: 'totally' }, { boom: 'shaka', meta: 'totally' }], Conrad::Collector.current.events
  end

  def test_metadata_is_isolated_across_threads
    emitter = CollectingEmitter.new

    Conrad::Collector.formatter = PASS_THROUGH
    Conrad::Collector.emitter = emitter
    Conrad::Collector.current.event_metadata = { meta: 'totally' }

    other_thread = Thread.new do
      Conrad::Collector.current.event_metadata = { separate_thread: true }

      Conrad::Collector.current.add_event(other_thread: 'multithread')

      Conrad::Collector.current.events
    end

    Conrad::Collector.current.add_event(first_thread: 'first')

    other_thread.join

    assert_equal [{ first_thread: 'first', meta: 'totally' }], Conrad::Collector.current.events
    assert_equal [{ separate_thread: true, other_thread: 'multithread' }], other_thread.value
  end

  def test_clears_events_and_metadata_after_sending_events
    Conrad::Collector.emitter = PASS_THROUGH
    Conrad::Collector.current.event_metadata = { whatever: 'who cares' }

    Conrad::Collector.current.add_event(foo: 'bar')
    Conrad::Collector.current.record_events

    assert_equal [], Conrad::Collector.current.events
    assert_equal({}, Conrad::Collector.current.event_metadata)
  end

  def test_allows_configuring_formatter_at_instance_level
    some_proc = ->(event) { event.to_s }
    collector = Conrad::Collector.new(formatter: some_proc)

    assert_equal some_proc, collector.formatter
  end

  def test_allows_configuring_processor_stack_at_instance_level
    some_proc = ->(event) { event.to_s }
    collector = Conrad::Collector.new(processors: [some_proc])

    assert_equal [some_proc], collector.processors.to_a
  end

  def test_allows_configuring_emitter_at_instance_level
    some_proc = ->(event) { event.to_s }
    collector = Conrad::Collector.new(emitter: some_proc)

    assert_equal some_proc, collector.emitter
  end
end
