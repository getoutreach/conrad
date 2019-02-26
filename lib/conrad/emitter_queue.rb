module Conrad
  class EmitterQueue
    include Singleton

    attr_reader :background
    attr_accessor :logger

    def initialize
      Thread.abort_on_exception = true
      @queue = Queue.new
      @logger ||= Logger.new(STDOUT)
    end

    def background=(value)
      @background = value
      start_thread if value
    end

    def enqueue
      @queue.push -> () { yield }
      
      # if it's backgounded we can break out of here, as the background
      #   queue will pick it up. otherwise, we need to explicitly process it
      process! unless background
    end

    private

    def process!
      until @queue.empty? do
        emit!
      end
    end

    def start_thread
      @thread ||= Thread.new do
        loop do
          unless @queue.empty?
            emit!
          end
        end
      end
    rescue e
      logger.error(e)
      @thread = nil
      start_thread
    end

    def emit!
      @queue.pop.call()
    end
  end
end