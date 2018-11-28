require_relative '../errors'
require_relative '../stdout_emitter'
require_relative '../json_formatter'

module OutreachAuditor
  # Provides the ability to record an event took place.
  # Currently recording an event accepts a hash and the values can only be one
  # of those classes listed as a scalar type. This is to prevent nesting of
  # data.
  #
  # @!attribute [r] formatter
  #    Configured formatter for creating the final event. Defaults to
  #    JSONFormatter.
  #    @see OutreachAuditor::JSONFormatter
  # @!attribute [r] emitter
  #    Configured emitter for sending the final event. Defaults to
  #    StdoutEmitter.
  #    @see OutreachAuditor::StdoutEmitter
  class Recorder
    # Allowed types for values given as audit event attributes
    SCALAR_TYPES = [String, Symbol, Integer, NilClass, FalseClass, TrueClass, Float].freeze

    attr_reader :formatter, :emitter, :middlewares

    def initialize(formatter: JSONFormatter.new, emitter: StdoutEmitter.new, middlewares: [])
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
