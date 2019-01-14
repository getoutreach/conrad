require 'conrad/formatters/json'
require 'conrad/emitters/stdout'
require 'conrad/processor_stack'
require 'conrad/errors'

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
  #
  # A single instance can also be created. By default it will use any values
  # configured for the class, but accepts override as keyword arguments.
  class Collector
    class << self
      # The set of Processors to use for each event added to each collector
      # created, by default. Must respond to #call
      attr_writer :default_processors

      # The Formatter to format each event added to each collector created, by
      #   default. Must respond to #call
      attr_writer :default_formatter

      # The Emitter to use for sending events to another place, added to each
      # collector by default. This should respond to #call. If `emit_as_batch`
      # is set to true, this method *must* accept an Array of events. Otherwise,
      # it is expected to accept a Hash.
      attr_writer :default_emitter

      # Boolean indicating if the events collected should be emitted as a batch
      # and sent as an Array to to the configured emitter or if they should
      # instead be sent one-by-one. Defaults to false.
      attr_accessor :default_emit_as_batch

      # Allows assigning a default logger to use for logging out of the gem.
      # Should respond to #debug, #info, #warn, #error, and #fatal.
      attr_accessor :default_logger

      # @return [Conrad::Collector] the collector for a given Thread that is
      #   currently active
      def current
        Thread.current[:conrad_collector] ||= new
      end

      # @return the configured formatter. Defaults to Conrad::Formatters::Json
      def default_formatter
        @default_formatter || Conrad::Formatters::JSON.new
      end

      # @return the configured emitter. Defaults to Conrad::Emitters::Stdout
      def default_emitter
        @default_emitter || Conrad::Emitters::Stdout.new
      end

      # @return [Array<#call>]
      def default_processors
        @default_processors || []
      end
    end

    # Used to setup metadata that will be added to every event in the collection
    attr_accessor :event_metadata

    # The events stored in the collector
    attr_reader :events

    # ProcessorStack used on each event added
    attr_reader :processors

    # Formatter used to generate sendable format for an Event
    attr_accessor :formatter

    # Emitter used to send out events
    attr_accessor :emitter

    # Boolean indicating if events should be sent as a batch or individually by
    #   default for each Collector instance
    attr_accessor :emit_as_batch
    alias emit_as_batch? emit_as_batch

    # Logger object used for sending log events
    attr_accessor :logger

    # @param processors [Array<#call>] set of processors to run. Defaults to
    #   processors as configured for the class.
    # @param formatter [#call] Formatter to use. Defaults to
    #   formatter as configured for the class.
    # @param emitter [#call] emitter to send events. Defaults to
    #   emitter as configured for the class.
    # @param emit_as_batch [Boolean] indicates how to send events. Defaults to
    #   value configured for class.
    def initialize(
      processors: self.class.default_processors,
      formatter: self.class.default_formatter,
      emitter: self.class.default_emitter,
      emit_as_batch: self.class.default_emit_as_batch,
      logger: self.class.default_logger
    )
      @events = []
      @event_metadata = {}
      @processors = processors
      @processor_stack = Conrad::ProcessorStack.new(processors)
      @formatter = formatter
      @emitter = emitter
      @emit_as_batch = emit_as_batch
      @logger = logger
    end

    # Adds an event to the Collector to be audited at a later time. The
    # current collector's event_metadata is added to the event, it is processed,
    # then it is formatter before being added to the set of events.
    # If `:halt_conrad_processing` is thrown during the event processing, then
    # the event will not be added to the collection.
    #
    # @param event [Hash]
    #
    # @raise [ForbiddenKey] when a key is neither a Symbol nor a String
    def add_event(event)
      processed_event = processor_stack.call(event.merge(event_metadata))

      return unless processed_event

      validate_event_keys(processed_event)

      events << formatter.call(processed_event)
    end

    # Records the events currently in the collection then clears the state of
    # the Collector by emptying the events stack and clearing out the metadata.
    #
    # @note Currently for emitting individual events, if an error is raised then
    #   a log message will be attempted using the configured logger. For batch
    #   emitted events, the error will be allowed to bubble up. This is to
    #   prevent the unexpected loss of events if a single one is malformed.
    def record_events
      if emit_as_batch?
        record_events_as_batch
      else
        record_individual_events
      end
    ensure
      reset_state
    end

    # Attribute writer for changing the processors for an instance of a
    # Collector
    def processors=(processors)
      @processor_stack = Conrad::ProcessorStack.new(processors)
      @processors = processors
    end

    # Adds the given hash of data to the already existing event metadata
    #
    # @param new_metadata [Hash]
    #
    # @return nothing
    def add_metadata(new_metadata)
      event_metadata.merge!(new_metadata)
    end

    private

    attr_reader :processor_stack

    def validate_event_keys(event)
      event.each_key do |key|
        raise ForbiddenKey, key unless key.is_a?(Symbol) || key.is_a?(String)
      end
    end

    def record_events_as_batch
      emitter.call(events)
    end

    def record_individual_events
      events.each do |event|
        begin
          emitter.call(event)
        rescue StandardError => e
          write_log(:error, e)
        end
      end
    end

    def reset_state
      event_metadata.clear
      events.clear
    end

    def write_log(level, data)
      return unless logger

      logger.public_send(level, data)
    end
  end
end
