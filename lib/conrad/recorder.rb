require 'conrad/errors'
require 'conrad/stdout_emitter'
require 'conrad/json_formatter'

module Conrad
  # Provides the ability to record an event took place.
  # Currently recording an event accepts a hash and passes it through the
  # configured processors, formatter, and emitter. Each of these may transform,
  # validate, format, and send the event as the user sees fit.
  #
  # @!attribute [r] formatter
  #    Configured formatter for creating the final event. Defaults to
  #    JSONFormatter.
  #    @see Conrad::JSONFormatter
  # @!attribute [r] emitter
  #    Configured emitter for sending the final event. Defaults to
  #    StdoutEmitter.
  #    @see Conrad::StdoutEmitter
  # @!attribute [r] processors
  #    Configured processors for processing the event pre-formatting and
  #    emission. Defaults to an empty array.
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
    def initialize(formatter: JSONFormatter.new, emitter: StdoutEmitter.new, processors: [])
      check_callability(formatter: formatter, emitter: emitter, processors: processors)

      @formatter = formatter
      @emitter = emitter
      @processors = processors
    end

    # Emits an audit event through the configured Emitter
    #
    # @param event [Hash] the set of key value pairs to be emitted
    #   as a single audit event. It is expected that all keys will be given as
    #   Symbols or Strings. All values should be of a type that matches the
    #   SCALAR_TYPES or an array once the processor cycle is complete but before
    #   final formatting.
    #
    # @raise [ForbiddenKey] when a key is neither a Symbol nor a String
    def audit_event(event)
      processed_event = processors.reduce(event) do |old_event, processor|
        processor.call(old_event)
      end

      validate_event_keys(processed_event)

      emitter.call(
        formatter.call(processed_event)
      )
    end

    private

    def check_callability(formatter:, emitter:, processors:)
      [formatter, emitter, *processors].each do |callable|
        raise ArgumentError, "#{callable} does not respond to `#call`" unless callable.respond_to?(:call)
      end
    end

    def validate_event_keys(event)
      event.each_key do |key|
        raise ForbiddenKey, key unless key.is_a?(Symbol) || key.is_a?(String)
      end
    end
  end
end
