module Conrad
  class EmitterQueue
    include Singleton

    attr_reader :background
    attr_accessor :logger

    def initialize
      @thread = nil
      @queue = Queue.new
      @logger ||= Logger.new(STDOUT)
    end

    def background=(bg)
      @background = bg
      start_thread if bg
      if end_thread?
        @queue.push -> () { throw :debackground }
        @thread.join
      end
    end

    def enqueue
      @queue.push -> () { yield }
      
      # if it's backgounded we can break out of here, as the background
      #   queue will pick it up. otherwise, we need to explicitly process it
      emit! unless @background
    end

    private

    def end_thread?
      @thread && !@background
    end

    def start_thread
      @thread ||= Thread.new do
        Thread.current.abort_on_exception = true
        catch :debackground do
          loop do
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
      until @queue.empty? do
        @queue.pop.call()
      end
    end
  end
end