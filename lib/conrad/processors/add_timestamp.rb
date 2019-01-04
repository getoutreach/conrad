require 'conrad/errors'

module Conrad
  module Processors
    # Used to add timestamps to an audit event in seconds or milliseconds.
    #
    # @!attribute [r] generator
    #    object used to generate the timestamp
    class AddTimestamp
      # :nodoc:
      class Error < Conrad::Error; end

      # Types of units supported for generation.
      ALLOWED_TIME_UNITS = %i[milliseconds seconds].freeze

      attr_reader :generator, :timestamp_key

      # Creates a new instance of AddTimestmap processor
      #
      # @param units [Symbol] type of time units for the timestamp generated.
      #   Allows :seconds or :milliseconds.
      # @param timestamp_key [Symbol] key to add to the event hash.
      # @raise [ArgumentError] if the given units value is not one of
      #   ALLOWED_TIME_UNITS
      def initialize(units: :milliseconds, timestamp_key: :timestamp)
        unless ALLOWED_TIME_UNITS.include? units
          raise ArgumentError, "Provided units of `#{units}` must be one of #{ALLOWED_TIME_UNITS}"
        end

        @generator = generator_from_units(units)
        @timestamp_key = timestamp_key
      end

      # Generates and adds a timestamp to the provided Hash.
      #
      # @param event [Hash]
      # @return [Hash]
      def call(event)
        event.merge(timestamp_key => generator.call)
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
end
