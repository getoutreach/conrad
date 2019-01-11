require 'forwardable'

module Conrad
  # @api private
  # Contains the main logic to share how processors are handled between the
  # individual, one-off recorder and the collector.
  class ProcessorStack
    include Enumerable
    extend Forwardable

    # The processors used by this Stack
    attr_reader :processors

    # Delegate #each and #to_a to the processors Array to allow iterating over
    # the object as if it were a collection of processors.
    def_delegators :processors, :each, :to_a

    # @param processors [Array<#call>] set of objects all responding to #call
    #   that will be used to process an event
    def initialize(processors)
      check_callability(processors)

      @processors = processors
    end

    # Processes an event through the defined set of operations, returning the
    # final hash. It is possible to `throw :halt_conrad_processing` to stop the
    # processing stack. There should be no additional arguments to the `throw`
    # call. At this point, the processing will stop and return nil.
    #
    # @return [nil, Hash] nil in the case that halt_conrad_processing has been
    #   caught, otherwise the result of all the processors which should be a
    #   Hash.
    def call(event)
      catch :halt_conrad_processing do
        processors.reduce(event) do |previous_built_event, processor|
          processor.call(previous_built_event)
        end
      end
    end

    private

    def check_callability(processors)
      processors.each do |processor|
        raise ArgumentError, "#{processor} does not respond to `#call`" unless processor.respond_to?(:call)
      end
    end
  end
end
