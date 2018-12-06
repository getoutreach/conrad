# frozen_string_literal: true

require 'test_helper'
require 'json'

class RecorderTest < Minitest::Test
  class TestMiddleware
    def self.call(event)
      event[:class_level] = true
      event
    end

    def self.proc_version
      lambda do |event|
        event[:proc_version] = true
        event
      end
    end

    def call(event)
      event[:instance_level] = true
      event
    end
  end

  def test_raises_an_argument_error_if_any_passed_items_do_not_respond_to_call
    formatter_exception = assert_raises(ArgumentError) { Conrad::Recorder.new(formatter: 'bad formatter') }
    emitter_exception = assert_raises(ArgumentError) { Conrad::Recorder.new(emitter: 'bad emitter') }
    middleware_exception = assert_raises(ArgumentError) do
      Conrad::Recorder.new(middlewares: ['bad middleware'])
    end

    assert_includes formatter_exception.message, 'bad formatter'
    assert_includes emitter_exception.message, 'bad emitter'
    assert_includes middleware_exception.message, 'bad middleware'
  end

  def test_calls_all_middlewares
    recorder = Conrad::Recorder.new(
      middlewares: [TestMiddleware, TestMiddleware.new, TestMiddleware.proc_version],
      emitter: return_event_proc,
      formatter: return_event_proc
    )

    recorded_event = recorder.audit_event(some_key: 'a magic value')

    assert recorded_event[:class_level] = true
    assert recorded_event[:instance_level] = true
    assert recorded_event[:proc_version] = true
    assert recorded_event[:some_key] = 'a magic value'
  end

  def test_does_not_modify_event_with_no_middleware
    recorder = Conrad::Recorder.new(
      emitter: return_event_proc,
      formatter: return_event_proc
    )

    recorded_event = recorder.audit_event(some_key: 'a magic value')

    assert recorded_event == { some_key: 'a magic value' }
  end

  def test_defaults_to_sending_formatted_events_to_stdout
    recorder = Conrad::Recorder.new(formatter: return_event_proc)
    event = { a: 'apple' }

    assert_output("#{event}\n") { recorder.audit_event(event) }
  end

  def test_defaults_to_json_formatter
    recorder = Conrad::Recorder.new
    event = { a: 'apple' }

    assert_output("#{event.to_json}\n") { recorder.audit_event(event) }
  end

  def test_uses_configured_formatted_if_provided
    formatter = lambda do |event|
      events = event.map do |key, value|
        "[#{key}] #{value}"
      end
      events.join(' ')
    end

    event = { a: 'apple', b: 'bear' }

    recorder = Conrad::Recorder.new(formatter: formatter)
    assert_output("#{formatter.call(event)}\n") { recorder.audit_event(event) }
  end

  def test_raises_forbidden_key_when_given_non_string_or_symbol_attribute
    assert_raises(Conrad::ForbiddenKey) do
      Conrad::Recorder.new.audit_event(1 => '')
    end

    assert_raises(Conrad::ForbiddenKey) do
      Conrad::Recorder.new.audit_event([1, 2, 3] => '')
    end

    assert_raises(Conrad::ForbiddenKey) do
      Conrad::Recorder.new.audit_event({} => '')
    end

    assert_raises(Conrad::ForbiddenKey) do
      Conrad::Recorder.new.audit_event(Conrad::Recorder.new => '')
    end
  end

  private

  def return_event_proc
    ->(event) { event }
  end
end
