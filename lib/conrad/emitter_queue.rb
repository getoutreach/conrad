module Conrad
  # Centralized event emission queue across threads
  class EmitterQueue
    include Singleton

    # Boolean that determines whether events will be emitted inline or in a
    #   background thread
    attr_reader :background

    # Logger object used for sending log events
    attr_accessor :logger

    def initialize
      @thread = nil
      @queue = Queue.new
      @logger ||= Logger.new(STDOUT)
    end

    # bakground setter. Will start/stop the background thread
    # @param value [Boolean] assigns whether events should be processed inline
    #   or in a separate thread.
    def background=(value)
      @background = value
      value ? start_thread : @thread = nil
    end

    # Enqueues a block
    # @yield block to execute. Will either run inline or separately depending on
    #   whether the queue is backgrounded
    def enqueue
      @queue.push -> { yield }

      # if it's backgounded we can break out of here, as the background
      #   queue will pick it up. otherwise, we need to explicitly process it
      emit! unless @background
    end

    private

    def start_thread
      @thread ||= Thread.new do
        Thread.current.abort_on_exception = true
        loop do
          emit!
          break unless Conrad::EmitterQueue.instance.background
        end
      end
    rescue e
      logger.error(e)
      @thread = nil
      start_thread
    end

    def emit!
      @queue.pop.call until @queue.empty?
    end
  end
end
