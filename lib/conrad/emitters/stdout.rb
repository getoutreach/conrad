module Conrad
  module Emitters
    # Basic emitter for sending events to $stdout.
    class Stdout < Base
      # Puts an event to $stdout.
      def emit(event)
        puts event
      end
    end
  end
end
