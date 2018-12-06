require 'conrad/errors'
require 'conrad/stdout_emitter'
require 'conrad/json_formatter'

module Conrad
  # Provides the ability to record an event took place.
  # Currently recording an event accepts a hash and the values can only be one
  # of those classes listed as a scalar type. This is to prevent nesting of
  # data.
  #
  # @!attribute [r] formatter
  #    Configured formatter for creating the final event. Defaults to
  #    JSONFormatter.
  #    @see Conrad::JSONFormatter
  # @!attribute [r] emitter
  #    Configured emitter for sending the final event. Defaults to
  #    StdoutEmitter.
  #    @see Conrad::StdoutEmitter
  # @!attribute [r] middlewares
  #    Configured middlewares for processing the event pre-formatting and
  #    emission. Defaults to an empty array.
  class Recorder
    # Allowed types for values given as audit event attributes
    SCALAR_TYPES = [String, Symbol, Integer, NilClass, FalseClass, TrueClass, Float].freeze

    attr_reader :formatter, :emitter, :middlewares

    # All arguments passed must *explicitly* respond to a `call` method.
    #
    # @param formatter [#call] formatter for creating the final event
    # @param emitter [#call] emitter for sending the final event
    # @param middlewares [Array<#call>] middlewares for processing the event
    #   pre-formatting and emission
    #
    # @raise [ArgumentError] if the formatter, emitter, or any of the
    #   middlewares do not respond_to? `call` with a truthy value.
    def initialize(formatter: JSONFormatter.new, emitter: StdoutEmitter.new, middlewares: [])
      check_callability(formatter: formatter, emitter: emitter, middlewares: middlewares)

      @formatter = formatter
      @emitter = emitter
      @middlewares = middlewares
    end

    # Emits an audit event through the configured Emitter
    #
    # @param event [Hash] the set of key value pairs to be emitted
    #   as a single audit event. It is expected that all keys will be given as
    #   Symbols or Strings. All values should be of a type that matches the
    #   SCALAR_TYPES or an array once middleware processing is complete but before
    #   final formatting.
    #
    # @raise [ForbiddenValue] when a final value of the unformatted event is not
    #   a valid type.
    # @raise [ForbiddenKey] when a key is neither a Symbol nor a String
    def audit_event(event)
      processed_event = middlewares.reduce(event) do |old_event, processor|
        processor.call(old_event)
      end

      validate_event_keys_and_values(processed_event)

      emitter.call(
        formatter.call(processed_event)
      )
    end

    private

    def check_callability(formatter:, emitter:, middlewares:)
      [formatter, emitter, *middlewares].each do |callable|
        raise ArgumentError, "#{callable} does not respond to `#call`" unless callable.respond_to?(:call)
      end
    end

    def validate_event_keys_and_values(event)
      event.each do |key, value|
        raise ForbiddenKey, key unless key.is_a?(Symbol) || key.is_a?(String)

        raise ForbiddenValue.new(key, value) unless valid_value_type?(value)
      end
    end

    def valid_value_type?(value)
      SCALAR_TYPES.any? { |type| value.is_a? type }
    end
  end
end
