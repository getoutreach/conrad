require 'conrad/errors'
require 'conrad/emitters/stdout'
require 'conrad/formatters/json'
require 'conrad/processor_stack'

module Conrad
  # Provides the ability to record an event took place.
  # Currently recording an event accepts a hash and passes it through the
  # configured processors, formatter, and emitter. Each of these may transform,
  # validate, format, and send the event as the user sees fit.
  #
  # @!attribute [r] formatter
  #    Configured formatter for creating the final event. Defaults to
  #    JSON.
  #    @see Conrad::Formatters::JSON
  # @!attribute [r] emitter
  #    Configured emitter for sending the final event. Defaults to
  #    Stdout.
  #    @see Conrad::Emitters::Stdout
  # @!attribute [r] processors
  #    Configured processors for processing the event pre-formatting and
  #    emission. Defaults to an empty enumerable.
  class Recorder
    attr_reader :formatter, :emitter, :processors

    # All arguments passed must *explicitly* respond to a `call` method.
    #
    # @param formatter [#call] formatter for creating the final event
    # @param emitter [#call] emitter for sending the final event
    # @param processors [Array<#call>] processors for processing the event
    #   pre-formatting and emission
    #
    # @raise [ArgumentError] if the formatter, emitter, or any of the
    #   processors do not respond_to? `call` with a truthy value.
    def initialize(
      formatter: Conrad::Formatters::JSON.new,
      emitter: Conrad::Emitters::Stdout.new,
      processors: []
    )
      check_callability(formatter: formatter, emitter: emitter)

      @formatter = formatter
      @emitter = emitter
      @processors = processors
      @processor_stack = Conrad::ProcessorStack.new(processors)
    end

    # Processes the given event, formats it, then emits it. It is possible
    # to `throw :halt_conrad_processing` to stop the processing stack. There
    # should be no additional arguments to the `throw` call. At this point, the
    # processing will stop and the audit event will be discarded. The formatter
    # and the emitter will not be called.
    #
    # @param event [Hash] the set of key value pairs to be emitted
    #   as a single audit event. It is expected that all keys will be given as
    #   Symbols or Strings.
    #
    # @raise [ForbiddenKey] when a key is neither a Symbol nor a String
    def audit_event(event)
      processed_event = processor_stack.call(event)

      return unless processed_event

      validate_event_keys(processed_event)

      format_and_emit(processed_event)
    end

    private

    attr_reader :processor_stack

    def validate_event_keys(event)
      event.each_key do |key|
        raise ForbiddenKey, key unless key.is_a?(Symbol) || key.is_a?(String)
      end
    end

    def format_and_emit(event)
      emitter.call(
        formatter.call(event)
      )
    end

    def check_callability(formatter:, emitter:)
      [formatter, emitter].each do |callable|
        raise ArgumentError, "#{callable} does not respond to `#call`" unless callable.respond_to?(:call)
      end
    end
  end
end
