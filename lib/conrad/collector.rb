require 'conrad/formatters/json'
require 'conrad/emitters/stdout'
require 'conrad/processor_stack'

module Conrad
  # Used to collect a batch of events and send them using the configured
  # emitter. This is especially useful for event recording done as part of a
  # request/response cycle. Events can be collected here then sent at the end of
  # the request cycle.
  #
  # Configuration is set via the class level and individual instances are
  # spawned that use this configuration. The exception to that is the
  # `event_metadata` which should be per collector using:
  # `Conrad::Collector.current.event_metadata = { whatever: 'you want' }`
  class Collector
    # Used to setup metadata that will be added to every event in the collection
    attr_accessor :event_metadata

    # The events stored in the collector
    attr_reader :events

    class << self
      # The set of Processors to use for each event added to the Collector
      attr_writer :processors

      # The Formatter to format each event added to the Collector
      attr_writer :formatter

      # The Emitter to use for sending events to another place. This should
      # respond to #call. If `emit_as_batch` is set to true, this method *must*
      # accept an Array of events. Otherwise, it is expected to accept a Hash.
      attr_writer :emitter

      # Boolean indicating if the events collected should be emitted as a batch
      # and sent as an Array to to the configured emitter or if they should
      # instead be sent one-by-one. Defaults to false.
      attr_writer :emit_as_batch

      # @return [Conrad::Collector] the collector for a given Thread that is
      #   currently active
      def current
        Thread.current[:conrad_collector] ||= new
      end

      # @return [Conrad::ProcessorStack] processors used for every event added
      #   to the collector. Uses the configured processors if available,
      #   otherwise initializes to an empty stack.
      def processor_stack
        @processor_stack ||= if @processors.nil?
                               Conrad::ProcessorStack.new
                             else
                               Conrad::ProcessorStack.new(@processors)
                             end
      end

      # @return the configured formatter. Defaults to Conrad::Formatters::Json
      def formatter
        @formatter ||= Conrad::Formatters::Json.new
      end

      # @return the configured emitter. Defaults to Conrad::Emitters::Stdout
      def emitter
        @emitter ||= Conrad::Emitters::Stdout
      end

      # @return [Boolean] indicator of if events should be emitted as a batch or
      #   individually
      def emit_as_batch?
        @emit_as_batch
      end
    end

    def initialize
      @events = []
    end

    # Adds an event to the Collector to be audited at a later time. The
    # current collector's event_metadata is added to the event, it is processed,
    # then it is formatter before being added to the set of events.
    # If `:halt_conrad_processing` is thrown during the event processing, then
    # the event will not be added to the collection.
    #
    # @param event [Hash]
    def add_event(event)
      processed_event = processors.call(event.merge(event_metadata))

      return unless processed_event

      events << formatter.call(processed_event)
    end

    # Records the events currently in the collection then clears the state of
    # the Collector by emptying the events stack and clearing out the metadata.
    def record_events
      if emit_as_batch?
        record_events_as_batch
      else
        record_individual_events
      end

      reset_state!
    end

    private

    def record_events_as_batch
      emitter.call(events)
    end

    def record_individual_events
      events.each do |event|
        emitter.call(event)
      end
    end

    def reset_state!
      event_metadata.clear
      events.clear
    end

    # Attributes read from the class variables set.
    def processors
      self.class.processor_stack
    end

    def formatter
      self.class.formatter
    end

    def emitter
      self.class.emitter
    end

    def emit_as_batch?
      self.class.emit_as_batch?
    end
  end
end
