module Conrad
  module Emitters
    # Basic emitter for sending events to $stdout.
    class StdoutEmitter
      # Puts an event to $stdout.
      def call(event)
        puts event
      end
    end
  end
end
