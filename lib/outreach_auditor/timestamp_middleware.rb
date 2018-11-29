require 'outreach_auditor/errors'

module OutreachAuditor
  # Used to add timestamps to an audit event in seconds or milliseconds.
  #
  # @!attribute [r] generator
  #    object used to generate the timestamp
  class TimestampMiddleware
    # :nodoc:
    class Error < OutreachAuditor::Error; end

    # Types of units supported for generation.
    ALLOWED_TIME_UNITS = %i[milliseconds seconds].freeze

    attr_reader :generator

    # Creates a new instance of Timestmap middleware
    #
    # @param units [Symbol] type of time units for the timestamp generated.
    #   Defaults to milliseconds.
    # @raise [ArgumentError] if the given units value is not one of
    #   ALLOWED_TIME_UNITS
    def initialize(units = :milliseconds)
      unless ALLOWED_TIME_UNITS.include? units
        raise ArgumentError, "Provided units of `#{units}` must be one of #{ALLOWED_TIME_UNITS}"
      end

      @generator = generator_from_units(units)
    end

    # Generates and adds a timestamp to the provided Hash.
    #
    # @param event [Hash]
    # @return [Hash]
    def call(event)
      event[:timestamp] = generator.call
      event
    end

    private

    def generator_from_units(units)
      case units
      when :milliseconds then -> { (Time.now.to_f * 1000).to_i }
      when :seconds then -> { Time.now.to_i }
      else
        raise UnrecognizedTimeUnit, units
      end
    end
  end
end
