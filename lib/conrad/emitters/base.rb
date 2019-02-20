require 'conrad/errors'

module Conrad
  module Emitters
    # Base class for emitters
    class Base
      def initialize(args = {})
        setup(args)
        @background = args[:background]
        background_process if @background
      end

      def call(event)
        if @background
          enqueue(event)
        else
          emit(event)
        end
      end

      private

      def setup(*); end

      attr_accessor :queue
      attr_accessor :background

      def enqueue(event)
        @queue.push(event)
      end

      def background_process
        @queue = Queue.new
        Thread.new do
          loop do
            unless @queue.empty?
              event = @queue.pop
              emit(event)
            end
          end
        end
      end
    end
  end
end
