module OutreachAuditor
  # Basic emitter for sending events to STDOUT.
  class StdoutEmitter
    # Puts an event to STDOUT. More or less an alias for `STDOUT.puts`
    def call(event)
      STDOUT.puts event
    end
  end
end
