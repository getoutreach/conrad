require 'conrad/errors'

module Conrad
  module Emitters
    class Base
      def initialize(args={})
        setup(args)
        background_delivery = args[:background_delivery]
        start_background_processing if background_delivery
      end

      def call(event)
        if background_delivery
          enqueue(event)
        else
          emit(event)
        end
      end

      private

      def setup(args={})
      end

      attr_accessor :queue
      attr_accessor :background_delivery

      def enqueue(event)
        queue.push(event)
      end

      def start_background_processing
        queue = Queue.new if background_delivery
        Thread.new do 
          unless queue.empty?
            event = queue.pop
            emit(event)
          end
        end
      end
    end
  end
end